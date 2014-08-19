//
//  ViewController.swift
//  ThreadsExperiment
//
//  Created by Simon Gladman on 02/08/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var uiView: UIView!
    @IBOutlet var parameterSlider: UISlider!
    @IBOutlet var parameterButtonBar: UISegmentedControl!
    @IBOutlet var parameterValueLabel: UILabel!


    
    var f : Double = 0.023;
    var k : Double = 0.0795;
    var dU : Double = 0.16;
    var dV : Double = 0.08;

    var grayScottData:GrayScottData = {
            var data = [GrayScottStruct]()
            for i in 0..<Constants.LENGTH_SQUARED
            {
                data.append(GrayScottStruct(u:1.0, v:0.0))
            }
            for i in 25 ..< 45
            {
                for j in 25 ..< 45
                {
                    if arc4random() % 100 > 5
                    {
                        data[i * Constants.LENGTH + j] = GrayScottStruct(u: 0.5, v: 0.25);
                    }
                }
            }
            return GrayScottData(data: data)
        }()
    var nextGrayScottData:GrayScottData = GrayScottData()


    override func viewDidLoad()
    {
        
        let timer = NSTimer.scheduledTimerWithTimeInterval(0.025, target: self, selector: Selector("timerHandler"), userInfo: nil, repeats: true);
        
        updateLabel();
        dispatchSolverOperation()
    }

    func timerHandler()
    {
        //self.dispatchSolverOperation()
    }
    
    @IBAction func sliderValueChangeHandler(sender: AnyObject)
    {
        switch parameterButtonBar.selectedSegmentIndex
        {
            case 0:
                f = Double(parameterSlider.value);
            case 1:
                k = Double(parameterSlider.value);
            case 2:
                dU = Double(parameterSlider.value);
            case 3:
                dV = Double(parameterSlider.value);
            default:
                f = Double(parameterSlider.value);
        }
        
        updateLabel();
    }
    

    @IBAction func parametrButtonBarChangeHandler(sender: AnyObject)
    {
        updateLabel();
    }
    
    private func updateLabel()
    {
        switch parameterButtonBar.selectedSegmentIndex
        {
            case 0:
                parameterValueLabel.text = "f = " + f.format();
                parameterSlider.value = Float(f);
            case 1:
                parameterValueLabel.text = "k = " + k.format();
                parameterSlider.value = Float(k);
            case 2:
                parameterValueLabel.text = "Du = " + dU.format();
                parameterSlider.value = Float(dU);
            case 3:
                parameterValueLabel.text = "Dv = " + dV.format();
                parameterSlider.value = Float(dV);
            default:
                parameterValueLabel.text = "";
        }
    }
    
    
    private func dispatchSolverOperation()
    {
        let currentGSD = grayScottData
        let nextGSD = nextGrayScottData
        let params = GrayScottParmeters(f: f, k: k, dU: dU, dV: dV)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            grayScottSolver(currentGSD.rawArray(), params, nextGSD)
            let newImage = renderGrayScott(nextGSD)
            dispatch_async(dispatch_get_main_queue()) {
                let gsdTmp = self.grayScottData
                self.grayScottData = self.nextGrayScottData
                self.nextGrayScottData = gsdTmp // Recycle the array object
                self.imageView.image = newImage
                self.dispatchSolverOperation()
            }
        }
    }
}

