//
//  SplashViewController.swift
//  DankRanks
//
//  Created by Jiang, Tony on 12/6/17.
//  Copyright © 2017 Jiang, Tony. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        view.addGestureRecognizer(tap)
        view.isUserInteractionEnabled = true
        
        let titleStyle = UIFont(name: "Torque-Bold", size: (Env.iPad ? 81 : 54))
        let textFontAttributes = [
            NSAttributedStringKey.font : titleStyle!,
            // Note: SKColor.whiteColor().CGColor breaks this
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.strokeColor: UIColor(red: 2.0/255, green: 0.0/255.0, blue: 185.0/255.0, alpha: 1),
            // Note: Use negative value here if you want foreground color to show
            NSAttributedStringKey.strokeWidth: -5
            ] as [NSAttributedStringKey : Any]
        
        let myMutableString = NSMutableAttributedString(string: "Rank It Out", attributes: textFontAttributes)
        let logoWidth = myMutableString.width(withConstrainedHeight: view.frame.height/6)
        let logoHeight = myMutableString.height(withConstrainedWidth: logoWidth)
        
        let logo = UITextView(frame: CGRect(x: 0, y: view.frame.height/15, width: logoWidth, height: logoHeight))
        logo.center.x = view.frame.width/2
        logo.attributedText = myMutableString
        logo.textAlignment = .center
        logo.textContainer.lineFragmentPadding = 0
        logo.textContainerInset = .zero
        logo.isScrollEnabled = false
        logo.isEditable = false
        logo.backgroundColor = UIColor.clear
        logo.layer.masksToBounds = false
        view.addSubview(logo)
        logo.alpha = 0
        
        let height = self.view.frame.height/10
        let ruler = UIImage(named: "ruler")
        let rulerView = UIImageView(image: ruler)
        rulerView.frame = CGRect(x: -100, y: view.frame.height + 100, width: logo.frame.width/3, height: height/5*4/3)
        //rulerView.contentMode = .scaleAspectFit
        //rulerView.clipsToBounds = true
        let finalFrame = CGRect(x: logo.frame.midX - logoWidth/2, y: logo.frame.maxY - 10, width: logo.frame.width, height: height/5*4)
        view.addSubview(rulerView)
        
        UIView.animate(withDuration: 1, animations: {
            self.fullRotate(object: rulerView)
            rulerView.transform = CGAffineTransform(rotationAngle: (-45 * CGFloat(Double.pi)) / 180.0)
            rulerView.center = CGPoint(x: self.view.frame.width/2, y: self.view.frame.height/3*2)
        }, completion: { _ in
            UIView.animate(withDuration: 1, animations: {
                self.fullRotate(object: rulerView)
                //rulerView.contentMode = .scaleAspectFit
                rulerView.transform = CGAffineTransform(rotationAngle: (0 * CGFloat(Double.pi)) / 180.0)
                rulerView.center = CGPoint(x: logo.frame.width*3, y: self.view.frame.height/2)
                rulerView.frame.size = CGSize(width: self.view.frame.width*1.5, height: height/5*4*3)
            }, completion: { _ in
                UIView.animate(withDuration: 1, animations: {
                    self.fullRotate(object: rulerView)
                    rulerView.center = CGPoint(x: self.view.frame.width * -0.5, y: self.view.frame.height/5)
                }, completion: { _ in
                    UIView.animate(withDuration: 1, animations: {
                        logo.alpha = 1
                        self.fullRotate(object: rulerView)
                        rulerView.center = CGPoint(x: self.view.frame.width, y: self.view.frame.height/5*4)
                        rulerView.frame.size = CGSize(width: logo.frame.width/3, height: height/5*4/3)
                    }, completion: { _ in
                        UIView.animate(withDuration: 2, animations: {
                            rulerView.frame = finalFrame
                        })
                    })
                })
            })
        })
        
        let when = DispatchTime.now() + 6 // change to # of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.performSegue(withIdentifier: "toHome", sender: self)
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "toHome", sender: self)
    }
        
}
