#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Functions that relate to beam detection such as checking for beam presence and
finding beam centroids.
"""
############
# Standard #
############
import logging

###############
# Third Party #
###############

##########
# Module #
##########
from .beamexceptions import NoBeamPresent
from .preprocessing import uint_resize_gauss

def get_opening(image, erode=1, dilate=1, kernel=np.ones((5,5),np.uint8)):
    img_erode = cv2.erode(image, kernel, iterations=erode)
    img_dilate = cv2.erode(img_erode, kernel, iterations=dilate)
    return img_dilate

def beam_is_present(M=None, image=None, contour=None, max_m0=10e5, min_m0=10):
    """
    Checks if there is a beam in the image by checking the value of the 
    zeroth moment.

    Kwargs:
        M (list): Moments of an image. 
        image (np.ndarray): Image to check beam presence for.
        contour (np.ndarray): Beam contour boundaries.

    Returns:
        bool. True if beam is present, False if not.
    """    
    try:
        if not (M['m00'] < max_m0 and M['m00'] > min_m0):
            raise BeamNotPresent
    except (TypeError, IndexError):
        if contour:
            M = get_moments(contour=contour)
        else:
            contour = get_largest_contour(image)
            M = get_moments(contour=contour)
        if not (M['m00'] < max_m0 and M['m00'] > min_m0):
            raise BeamNotPresent

def detect(image, resize=1.0, kernel=(11,11)):
    """
    Checks for beam presence and returns the centroid and bounding box 
    of the beam. Returns None if no beam is present.

    Args:
        image (np.ndarray): Image to find the beam on.
    Kwargs:
        resize (float): Resize factor (1.0 keeps image same size).
        kernel (tuple): Tuple of length 2 for gaussian kernel size.        
    Returns:
        tuple. Tuple of centroid and bounding box. None, None if no beam is
            present.
    """
    image_prep = uint_resize_gauss(image, fx=resize, fy=resize, kernel=kernel)
    contour = get_largest_contour(image_prep)
    M = get_moments(contour=contour)
    centroid, bounding_box = None, None
    if beam_is_present(M):
        centroid     = [pos//resize for pos in get_centroid(M)]
        bounding_box = [val//resize for val in get_bounding_box(image_prep, 
                                                                contour)]
    return centroid, bounding_box

def find(image):
    """
    Returns the centroid and bounding box of the beam.

    Args:
        image (np.ndarray): Image to find the beam on.
    Kwargs:
        resize (float): Resize factor (1.0 keeps image same size).
        kernel (tuple): Tuple of length 2 for gaussian kernel size.        
    Returns:
        tuple. Tuple of centroid and bounding box. None, None if no beam is
            present.

    This method assumes that beam is known to be present.
    """
    image_prep = uint_resize_gauss(image, fx=resize, fy=resize, kernel=kernel)
    contour = get_largest_contour(image_prep)
    M = get_moments(contour=contour)
    centroid     = [pos//resize for pos in get_centroid(M)]
    bounding_box = [val//resize for val in get_bounding_box(image_prep, 
                                                            contour)]
    return centroid, bounding_box