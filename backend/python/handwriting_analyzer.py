import cv2
import numpy as np
import pytesseract
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
import logging
from typing import List, Tuple, Dict, Any
import io
from PIL import Image
import math

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter()

pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"


def preprocess_image(img: np.ndarray) -> np.ndarray:
    """
    Enhanced preprocessing for handwriting analysis.
    Applies multiple techniques for better text detection.
    """
    # Convert to grayscale if needed
    if len(img.shape) == 3:
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    else:
        gray = img.copy()
    
    # Enhanced resizing for better handwriting analysis
    height, width = gray.shape
    target_height = 800  # Optimal height for analysis
    target_width = 1200  # Optimal width for analysis
    
    # Calculate scale factors
    height_scale = target_height / height if height > 0 else 1
    width_scale = target_width / width if width > 0 else 1
    
    # Use the smaller scale factor to maintain aspect ratio
    scale_factor = min(height_scale, width_scale)
    
    # Only resize if the image is significantly different from target size
    if scale_factor < 0.5 or scale_factor > 2.0:
        new_height = int(height * scale_factor)
        new_width = int(width * scale_factor)
        
        # Use appropriate interpolation method
        if scale_factor > 1:
            # Upscaling - use cubic interpolation for better quality
            gray = cv2.resize(gray, (new_width, new_height), interpolation=cv2.INTER_CUBIC)
        else:
            # Downscaling - use area interpolation to avoid artifacts
            gray = cv2.resize(gray, (new_width, new_height), interpolation=cv2.INTER_AREA)
    
    # Apply bilateral filter to reduce noise while preserving edges
    denoised = cv2.bilateralFilter(gray, 9, 75, 75)
    
    # Enhance contrast using CLAHE with optimized parameters
    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(denoised)
    
    # Apply adaptive thresholding with optimized parameters
    binary = cv2.adaptiveThreshold(
        enhanced, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 15, 5
    )
    
    # Apply morphological operations to clean up the image
    kernel = np.ones((2, 2), np.uint8)
    cleaned = cv2.morphologyEx(binary, cv2.MORPH_CLOSE, kernel)
    cleaned = cv2.morphologyEx(cleaned, cv2.MORPH_OPEN, kernel)
    
    return cleaned


def get_text_contours_enhanced(img: np.ndarray) -> List[Tuple[int, int, int, int]]:
    """
    Enhanced text detection using multiple methods for better handwriting recognition.
    """
    boxes = []
    
    # Method 1: Advanced contour detection with better preprocessing
    preprocessing_methods = [
        lambda x: x,  # Original
        lambda x: cv2.bitwise_not(x),  # Inverted
        lambda x: cv2.GaussianBlur(x, (3, 3), 0),  # Blurred
        lambda x: cv2.medianBlur(x, 3),  # Median blur
        lambda x: cv2.bilateralFilter(x, 9, 75, 75),  # Bilateral filter
        lambda x: cv2.adaptiveThreshold(x, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2),  # Adaptive threshold
        lambda x: cv2.adaptiveThreshold(x, 255, cv2.ADAPTIVE_THRESH_MEAN_C, cv2.THRESH_BINARY, 15, 3),  # Mean threshold
    ]
    
    for i, preprocess_func in enumerate(preprocessing_methods):
        processed = preprocess_func(img)
        
        # Apply morphological operations for cleanup
        kernel = np.ones((2, 2), np.uint8)
        processed = cv2.morphologyEx(processed, cv2.MORPH_CLOSE, kernel)
        processed = cv2.morphologyEx(processed, cv2.MORPH_OPEN, kernel)
        
        # Find contours
        contours, _ = cv2.findContours(processed, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        for contour in contours:
            area = cv2.contourArea(contour)
            if area < 5:  # Even lower minimum area for handwriting
                continue
                
            x, y, w, h = cv2.boundingRect(contour)
            
            # More flexible filtering for handwriting
            aspect_ratio = w / h if h > 0 else 0
            
            # Very flexible criteria for handwriting detection
            if (0.01 <= aspect_ratio <= 100 and  # Extremely flexible aspect ratio
                h >= 1 and w >= 1 and           # Very low minimum dimensions
                area >= 3):                     # Very low minimum area
                boxes.append((x, y, w, h))
    
    # Remove duplicate boxes
    if boxes:
        boxes = remove_overlapping_boxes(boxes)
    
    return boxes


def remove_overlapping_boxes(boxes: List[Tuple[int, int, int, int]], 
                           overlap_threshold: float = 0.7) -> List[Tuple[int, int, int, int]]:
    """
    Remove overlapping bounding boxes, keeping the one with larger area.
    """
    if not boxes:
        return []
    
    # Sort by area (largest first)
    boxes_with_area = [(box, box[2] * box[3]) for box in boxes]
    boxes_with_area.sort(key=lambda x: x[1], reverse=True)
    
    filtered_boxes = []
    
    for box, area in boxes_with_area:
        is_overlapping = False
        
        for existing_box in filtered_boxes:
            # Calculate intersection
            x1 = max(box[0], existing_box[0])
            y1 = max(box[1], existing_box[1])
            x2 = min(box[0] + box[2], existing_box[0] + existing_box[2])
            y2 = min(box[1] + box[3], existing_box[1] + existing_box[3])
            
            if x1 < x2 and y1 < y2:
                intersection_area = (x2 - x1) * (y2 - y1)
                union_area = area + (existing_box[2] * existing_box[3]) - intersection_area
                
                if union_area > 0 and intersection_area / union_area > overlap_threshold:
                    is_overlapping = True
                    break
        
        if not is_overlapping:
            filtered_boxes.append(box)
    
    return filtered_boxes


def group_boxes_into_lines_enhanced(boxes: List[Tuple[int, int, int, int]], 
                                   line_height_threshold: float = 1.8) -> Dict[int, List[Tuple[int, int, int, int]]]:
    """
    Enhanced line grouping with better handling of handwriting variations.
    """
    if not boxes:
        return {}
    
    # Sort boxes by y-coordinate (top to bottom)
    sorted_boxes = sorted(boxes, key=lambda box: box[1])
    
    lines = {}
    current_line = 0
    current_y = sorted_boxes[0][1]
    current_height = sorted_boxes[0][3]
    
    lines[current_line] = []
    
    for box in sorted_boxes:
        x, y, w, h = box
        
        # Check if this box belongs to the current line
        y_center = y + h // 2
        current_y_center = current_y + current_height // 2
        
        # More flexible line grouping for handwriting
        if abs(y_center - current_y_center) > current_height * line_height_threshold:
            current_line += 1
            lines[current_line] = []
            current_y = y
            current_height = h
        
        lines[current_line].append(box)
    
    # Sort boxes within each line by x-coordinate (left to right)
    for line_num in lines:
        lines[line_num] = sorted(lines[line_num], key=lambda box: box[0])
    
    return lines


def calc_micrography_score_enhanced(boxes: List[Tuple[int, int, int, int]]) -> float:
    """
    New micrography detection using median-based approach.
    More robust for natural handwriting variations.
    """
    if not boxes or len(boxes) < 3:
        return 0.0

    # Get character heights (more reliable than area for micrography)
    heights = [h for (_, _, _, h) in boxes]
    
    if not heights or max(heights) <= 0:
        return 0.0
    
    # Use median as baseline (more robust than mean)
    median_height = np.median(heights)
    
    # Calculate percentage of characters that deviate significantly from median
    deviation_threshold = median_height * 0.4  # 40% deviation threshold
    anomalous_chars = 0
    
    for height in heights:
        deviation = abs(height - median_height)
        if deviation > deviation_threshold:
            anomalous_chars += 1
    
    # Calculate anomaly ratio
    anomaly_ratio = anomalous_chars / len(heights)
    
    # Apply smoothing function for more natural scoring
    if anomaly_ratio < 0.1:  # Less than 10% anomalous = excellent
        return 0.0
    elif anomaly_ratio < 0.3:  # Less than 30% anomalous = good
        return anomaly_ratio * 0.5
    elif anomaly_ratio < 0.5:  # Less than 50% anomalous = fair
        return anomaly_ratio * 0.7
    else:  # More than 50% anomalous = poor
        return min(anomaly_ratio, 1.0)


def analyze_handwriting_characteristics(boxes: List[Tuple[int, int, int, int]]) -> Dict[str, Any]:
    """
    Universal text analysis for any font type (handwriting, printed, etc.).
    Optimized for multiple languages and font styles.
    """
    if not boxes:
        return {
            "micrography_score": 0.0,
            "size_consistency": 0.0,
            "alignment_quality": 0.0,
            "spacing_regularity": 0.0,
            "baseline_stability": 0.0,
            "character_count": 0,
            "avg_height": 0.0,
            "avg_width": 0.0,
            "height_variance": 0.0,
            "width_variance": 0.0,
            "baseline_variance": 0.0,
            "spacing_variance": 0.0,
            "overall_quality_score": 0.0,
            "canvas_size_analysis": "no_characters"
        }
    
    heights = [h for _, _, _, h in boxes]
    widths = [w for _, _, w, _ in boxes]
    y_coords = [y for _, y, _, _ in boxes]
    x_coords = [x for x, _, _, _ in boxes]
    baselines = [y + h for _, y, _, h in boxes]
    
    # Basic statistics
    mean_height = np.mean(heights)
    mean_width = np.mean(widths)
    height_std = np.std(heights)
    width_std = np.std(widths)
    
    # Micrography analysis
    micro_score = calc_micrography_score_enhanced(boxes)
    
    # Size consistency analysis - much more flexible for natural handwriting
    if mean_height > 0:
        height_cv = height_std / mean_height
        # Much more flexible thresholds for natural handwriting
        if height_cv < 0.35:  # Very consistent (natural handwriting)
            size_consistency = 1.0
        elif height_cv < 0.55:  # Good consistency (natural handwriting)
            size_consistency = 0.9
        elif height_cv < 0.75:  # Fair consistency (natural handwriting)
            size_consistency = 0.7
        elif height_cv < 0.95:  # Poor consistency (natural handwriting)
            size_consistency = 0.4
        else:  # Very poor consistency (natural handwriting)
            size_consistency = 0.1
    else:
        size_consistency = 0
    
    # Simple alignment quality - just check if characters are roughly on same baseline
    if len(boxes) >= 2:
        # Get y-coordinates of character centers
        char_centers_y = [y + h/2 for _, y, _, h in boxes]
        baseline_variance = np.var(char_centers_y)
        
        # Simple alignment score based on baseline variance
        if baseline_variance < 100:  # Very well aligned
            alignment_quality = 1.0
        elif baseline_variance < 200:  # Well aligned
            alignment_quality = 0.8
        elif baseline_variance < 400:  # Fairly aligned
            alignment_quality = 0.6
        elif baseline_variance < 800:  # Poorly aligned
            alignment_quality = 0.3
        else:  # Very poorly aligned
            alignment_quality = 0.1
    else:
        alignment_quality = 1.0  # Not enough characters for analysis
    
    # Spacing regularity analysis - universal for any font type
    spacing_regularity = 1.0
    if len(boxes) >= 3:
        spacings = []
        for i in range(len(boxes) - 1):
            x1, _, w1, _ = boxes[i]
            x2, _, _, _ = boxes[i + 1]
            spacing = x2 - (x1 + w1)
            spacings.append(spacing)
        
        if spacings:
            spacing_std = np.std(spacings)
            mean_spacing = np.mean(spacings)
            if mean_spacing > 0:
                spacing_cv = spacing_std / mean_spacing
                # Universal thresholds for any font type
                if spacing_cv < 0.3:  # Very regular spacing (any font)
                    spacing_regularity = 1.0
                elif spacing_cv < 0.5:  # Regular spacing (any font)
                    spacing_regularity = 0.8
                elif spacing_cv < 0.7:  # Fairly regular spacing (any font)
                    spacing_regularity = 0.6
                elif spacing_cv < 0.9:  # Irregular spacing (any font)
                    spacing_regularity = 0.3
                else:  # Very irregular spacing (any font)
                    spacing_regularity = 0.1
    
    # Baseline stability - universal for any font type
    if len(baselines) > 1:
        baseline_variance = np.var(baselines)
        if mean_height > 0:
            baseline_cv = np.sqrt(baseline_variance) / mean_height
            # Universal thresholds for any font type
            if baseline_cv < 0.15:  # Very stable baseline (any font)
                baseline_stability = 1.0
            elif baseline_cv < 0.25:  # Stable baseline (any font)
                baseline_stability = 0.9
            elif baseline_cv < 0.4:  # Fairly stable baseline (any font)
                baseline_stability = 0.7
            elif baseline_cv < 0.6:  # Unstable baseline (any font)
                baseline_stability = 0.4
            else:  # Very unstable baseline (any font)
                baseline_stability = 0.1
        else:
            baseline_stability = 0
    else:
        baseline_stability = 1.0
    
    # Mobile-optimized analysis - no canvas size warnings for mobile
    canvas_size_analysis = "optimal_size"  # Always optimal for mobile
    
    # Overall quality score
    overall_quality = (
        size_consistency * 0.25 +
        alignment_quality * 0.25 +
        spacing_regularity * 0.25 +
        baseline_stability * 0.25
    )
    
    return {
        "micrography_score": round(float(micro_score), 3),
        "size_consistency": round(float(size_consistency), 3),
        "alignment_quality": round(float(alignment_quality), 3),
        "spacing_regularity": round(float(spacing_regularity), 3),
        "baseline_stability": round(float(baseline_stability), 3),
        "character_count": len(boxes),
        "avg_height": round(float(mean_height), 2),
        "avg_width": round(float(mean_width), 2),
        "height_variance": round(float(height_std ** 2), 2),
        "width_variance": round(float(width_std ** 2), 2),
        "baseline_variance": round(float(np.var(baselines) if len(baselines) > 1 else 0), 2),
        "spacing_variance": round(float(np.var(spacings) if 'spacings' in locals() and spacings else 0), 2),
        "overall_quality_score": round(float(overall_quality), 3),
        "canvas_size_analysis": canvas_size_analysis
    }


@router.post("/analyze_handwriting")
async def analyze_handwriting(image: UploadFile = File(...)):
    """
    Enhanced handwriting analysis with comprehensive reporting.
    """
    # Validate file type
    if not image.filename.lower().endswith(('.png', '.jpg', '.jpeg')):
        raise HTTPException(
            status_code=400, 
            detail="Only PNG, JPG, and JPEG files are accepted"
        )

    try:
        # Read and decode image
        image_bytes = await image.read()
        
        # Try multiple methods to read the image
        img = None
        try:
            # Method 1: OpenCV
            nparr = np.frombuffer(image_bytes, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        except:
            pass
            
        if img is None:
            try:
                # Method 2: PIL + conversion
                pil_img = Image.open(io.BytesIO(image_bytes))
                img = cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)
            except:
                pass
        
        if img is None:
            raise ValueError("Could not decode image. Please check the file format.")

        logger.info(f"Image loaded successfully. Shape: {img.shape}")
        
        # Enhanced preprocessing
        processed_img = preprocess_image(img)
        
        # Try multiple detection methods
        lines = {}
        detection_method = "none"
        
        # Method 1: Enhanced contour detection (primary method for handwriting)
        try:
            logger.info("Using enhanced contour detection for handwriting")
            boxes = get_text_contours_enhanced(processed_img)
            lines = group_boxes_into_lines_enhanced(boxes)
            detection_method = "enhanced_contour"
            logger.info(f"Enhanced contour method detected {sum(len(line_boxes) for line_boxes in lines.values())} text elements")
        except Exception as e:
            logger.warning(f"Enhanced contour detection failed: {e}")
        
        # Method 2: Tesseract OCR as fallback
        if not lines:
            try:
                logger.info("Using Tesseract OCR as fallback")
                data = pytesseract.image_to_data(
                    processed_img, 
                    lang="tur",  # Türkçe dil desteği
                    output_type=pytesseract.Output.DICT,
                    config='--psm 6'
                )
                
                # Group by line number
                for i, text in enumerate(data["text"]):
                    if text.strip() == "" or data["conf"][i] < 10:
                        continue
                        
                    line_num = data["line_num"][i]
                    x, y, w, h = data["left"][i], data["top"][i], data["width"][i], data["height"][i]
                    
                    if w < 5 or h < 5:
                        continue
                        
                    if line_num not in lines:
                        lines[line_num] = []
                    lines[line_num].append((x, y, w, h))
                
                detection_method = "tesseract"
                logger.info(f"Tesseract detected {len([t for t in data['text'] if t.strip()])} text elements")
                
            except Exception as tesseract_error:
                logger.warning(f"Tesseract failed: {tesseract_error}")

        if not lines:
            return JSONResponse(content={
                "status": "warning",
                "message": "No handwriting or text detected. Please ensure the image contains clear handwritten text.",
                "analysis_type": "handwriting",
                "total_lines_detected": 0,
                "line_analysis_results": [],
                "debug_info": {
                    "image_shape": list(img.shape),
                    "preprocessing_applied": True,
                    "detection_method": detection_method
                }
            })

        # Analyze each line with enhanced analysis
        analysis_results = []
        for line_num, boxes in lines.items():
            if not boxes:
                continue
            
            line_analysis = analyze_handwriting_characteristics(boxes)
            line_analysis["line_number"] = int(line_num)
            analysis_results.append(line_analysis)

        # Sort results by line number
        analysis_results.sort(key=lambda x: x["line_number"])
        
        # Calculate comprehensive overall statistics
        total_chars = sum(result["character_count"] for result in analysis_results)
        avg_micrography = float(np.mean([result["micrography_score"] for result in analysis_results])) if analysis_results else 0.0
        avg_quality = float(np.mean([result["overall_quality_score"] for result in analysis_results])) if analysis_results else 0.0
        avg_size_consistency = float(np.mean([result["size_consistency"] for result in analysis_results])) if analysis_results else 0.0
        avg_alignment = float(np.mean([result["alignment_quality"] for result in analysis_results])) if analysis_results else 0.0
        avg_spacing = float(np.mean([result["spacing_regularity"] for result in analysis_results])) if analysis_results else 0.0
        avg_baseline = float(np.mean([result["baseline_stability"] for result in analysis_results])) if analysis_results else 0.0
        
        # New severity levels based on median-based micrography detection
        micrography_severity = "none"
        if avg_micrography > 0.60:  # More than 65% characters are anomalous
            micrography_severity = "severe"
        elif avg_micrography > 0.4:  # More than 40% characters are anomalous
            micrography_severity = "moderate"
        elif avg_micrography > 0.15:  # More than 15% characters are anomalous
            micrography_severity = "mild"
        
        # Much more flexible quality assessment for natural handwriting
        overall_handwriting_quality = "excellent"
        if avg_quality < 0.25:  # Much lower threshold for poor
            overall_handwriting_quality = "poor"
        elif avg_quality < 0.45:  # Lower threshold for fair
            overall_handwriting_quality = "fair"
        elif avg_quality < 0.65:  # Lower threshold for good
            overall_handwriting_quality = "good"

        return JSONResponse(content={
            "status": "success",
            "analysis_type": "universal_text",
            "total_lines_detected": len(analysis_results),
            "total_characters_detected": int(total_chars),
            "overall_micrography_score": round(avg_micrography, 3),
            "micrography_severity": micrography_severity,
            "overall_quality_score": round(avg_quality, 3),
            "overall_handwriting_quality": overall_handwriting_quality,
            "size_consistency_score": round(avg_size_consistency, 3),
            "alignment_quality_score": round(avg_alignment, 3),
            "spacing_regularity_score": round(avg_spacing, 3),
            "baseline_stability_score": round(avg_baseline, 3),
            "interpretation": {
                "micrography_detected": bool(avg_micrography > 0.1),
                "good_size_consistency": bool(avg_size_consistency > 0.6),  # Universal threshold
                "good_alignment": bool(avg_alignment > 0.6),  # Universal threshold
                "regular_spacing": bool(avg_spacing > 0.5),  # Universal threshold
                "stable_baseline": bool(avg_baseline > 0.6),  # Universal threshold
                "overall_quality_good": bool(avg_quality > 0.6)  # Universal threshold
            },
            "universal_text_notes": {
                "optimized_for_all_fonts": True,
                "supports_multiple_languages": "Supports any language and font type",
                "natural_variation_expected": "Natural variations expected in any font type",
                "baseline_flexibility": "Baseline flexibility for all font types"
            },
            "line_analysis_results": analysis_results,
            "debug_info": {
                "image_shape": list(img.shape),
                "preprocessing_applied": True,
                "detection_method": detection_method,
                "font_optimization": "universal",
                "canvas_size_analysis": {
                    "original_size": f"{img.shape[1]}x{img.shape[0]}",
                    "target_size": "1200x800",
                    "resize_applied": "yes" if img.shape[0] != 800 or img.shape[1] != 1200 else "no"
                }
            }
        })

    except Exception as e:
        logger.error(f"Handwriting analysis error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Server error: {str(e)}")


@router.get("/health_handwriting")
async def health_check_handwriting():
    """Health check endpoint for the handwriting analysis service."""
    try:
        # Test if Tesseract is accessible
        test_img = np.ones((100, 100), dtype=np.uint8) * 255
        cv2.putText(test_img, "TEST", (10, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, 0, 2)
        _ = pytesseract.image_to_string(test_img)
        tesseract_status = "healthy"
    except:
        tesseract_status = "unavailable"
    
    return {
        "status": "healthy",
        "tesseract_status": tesseract_status,
        "opencv_version": cv2.__version__
    }