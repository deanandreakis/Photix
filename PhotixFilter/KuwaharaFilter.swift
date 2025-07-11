//
//  KuwaharaFilter.swift
//  PhotixFilter
//
//  Created by Dean Andreakis on 9/29/18.
//  Copyright © 2018 deanware. All rights reserved.
//

import CoreImage

@objc public class KuwaharaFilter: CIFilter
{
    @objc public var inputImage: CIImage?
    @objc public var inputRadius: CGFloat = 15
    
    public override var attributes: [String : Any]
    {
        return [
            kCIAttributeFilterDisplayName: "Kuwahara Filter" as AnyObject,
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputRadius": [kCIAttributeIdentity: 0,
                            kCIAttributeClass: "NSNumber",
                            kCIAttributeDefault: 15,
                            kCIAttributeDisplayName: "Radius",
                            kCIAttributeMin: 0,
                            kCIAttributeSliderMin: 0,
                            kCIAttributeSliderMax: 30,
                            kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    public override func setDefaults()
    {
        inputRadius = 15
    }
    
    let kuwaharaKernel = CIKernel(source:
        "kernel vec4 kuwahara(sampler image, float r) \n" +
            "{" +
            "   vec2 d = destCoord();" +
            
            "   int radius = int(r); " +
            "   float n = float((radius + 1) * (radius + 1)); " +
            
            "   vec3 means[4]; " +
            "   vec3 stdDevs[4]; " +
            
            "   for (int i = 0; i < 4; i++) " +
            "   { " +
            "       means[i] = vec3(0.0); " +
            "       stdDevs[i] = vec3(0.0); " +
            "   } " +
            
            "   for (int x = -radius; x <= radius; x++) " +
            "   { " +
            "       for (int y = -radius; y <= radius; y++) " +
            "       { " +
            "           vec3 color = sample(image, samplerTransform(image, d + vec2(x,y))).rgb; \n" +
            
            "           vec3 colorA = vec3(float(x <= 0 && y <= 0)) * color; " +
            "           means[0] += colorA; " +
            "           stdDevs[0] += colorA * colorA; " +
            
            "           vec3 colorB = vec3(float(x >= 0 && y <= 0)) * color; " +
            "           means[1] +=  colorB; " +
            "           stdDevs[1] += colorB * colorB; " +
            
            "           vec3 colorC = vec3(float(x <= 0 && y >= 0)) * color; " +
            "           means[2] += colorC; " +
            "           stdDevs[2] += colorC * colorC; " +
            
            "           vec3 colorD = vec3(float(x >= 0 && y >= 0)) * color; " +
            "           means[3] += colorD; " +
            "           stdDevs[3] += colorD * colorD; " +
            
            "       } " +
            "   } " +
            
            "   float minSigma2 = 1e+2;" +
            "   vec3 returnColor = vec3(0.0); " +
            
            "   for (int j = 0; j < 4; j++) " +
            "   { " +
            "       means[j] /= n; " +
            "       stdDevs[j] = abs(stdDevs[j] / n - means[j] * means[j]); \n" +
            
            "       float sigma2 = stdDevs[j].r + stdDevs[j].g + stdDevs[j].b; \n" +
            
            "       returnColor = (sigma2 < minSigma2) ? means[j] : returnColor; " +
            "       minSigma2 = (sigma2 < minSigma2) ? sigma2 : minSigma2; " +
            "   } " +
            
            "   return vec4(returnColor, 1.0); " +
        "}"
    )
    
    @objc public override var outputImage : CIImage!
    {
        if let inputImage = inputImage,
            let kuwaharaKernel = kuwaharaKernel
        {
            let arguments = [inputImage, inputRadius] as [Any]
            let extent = inputImage.extent
            
            return kuwaharaKernel.apply(extent: extent,
                                                  roiCallback:
                {
                    (index, rect) in
                    return rect
            },
                                                  arguments: arguments)
        }
        return nil
    }
}
