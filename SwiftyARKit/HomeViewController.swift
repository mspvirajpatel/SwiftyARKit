//
//  HomeViewController.swift
//  VPARkit
//
//  Created by Viraj Patel on 06/11/17.
//  Copyright © 2017 Viraj Patel. All rights reserved.
//

import Foundation
import ARKit

enum FunctionMode {
    case none
    case placeObject(String)
    case measure
}

class HomeViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
   
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var trackingInfo: UILabel!
    
    @IBOutlet weak var chairButton: UIButton!
    @IBOutlet weak var candleButton: UIButton!
    @IBOutlet weak var measureButton: UIButton!
    
    @IBOutlet weak var crosshair: UIView!
    
    let collisionCatBottom  = 1 << 0  //1
    let collisionCatCube    = 1 << 1  //2
    
    var currentMode: FunctionMode = .none
    var objects: [SCNNode] = []
    var measuringNodes: [SCNNode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        runSession()
        trackingInfo.text = ""
        messageLabel.text = ""
        distanceLabel.isHidden = true
        selectVase()
    }
    
    @IBAction func didTapChair(_ sender: Any) {
        currentMode = .placeObject("Models.scnassets/chair/chair.scn")
        selectButton(chairButton)
    }
    
    @IBAction func didTapCandle(_ sender: Any) {
        currentMode = .placeObject("Models.scnassets/dragon/dragon.scn")
        selectButton(candleButton)
    }
    
    @IBAction func didTapMeasure(_ sender: Any) {
        currentMode = .measure
        selectButton(measureButton)
    }
    
    @IBAction func didTapVase(_ sender: Any) {
        selectVase()
    }
    
    @IBAction func didTapReset(_ sender: Any) {
        removeAllObjects()
        distanceLabel.text = ""
    }
    
    func selectVase() {
        currentMode = .placeObject("Models.scnassets/chair/chair.scn")
        selectButton(chairButton)
    }
    
    func selectButton(_ button: UIButton) {
        unselectAllButtons()
        button.isSelected = true
    }
    
    func unselectAllButtons() {
        [chairButton, candleButton, measureButton].forEach {
            $0?.isSelected = false
        }
    }
    
    func removeAllObjects() {
        for object in objects {
            object.removeFromParentNode()
        }
        
        objects = []
    }
    
    func runSession() {
        sceneView.delegate = self
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration)
        #if DEBUG
            sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        #endif
        
        
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touchLocation = touches.first?.location(in: sceneView)
        {
            if let hit = sceneView.hitTest(touchLocation, options: nil).first {
                if hit.node.name != "Plane"
                {
                    hit.node.removeFromParentNode()
                    return
                }
                
            }
        }
        
        
        if let hit = sceneView.hitTest(viewCenter, types: [.existingPlaneUsingExtent]).first {
            sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            return
        } else if let hit = sceneView.hitTest(viewCenter, types: [.featurePoint]).last {
            sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            return
        }
    }
    
    func measure(fromNode: SCNNode, toNode: SCNNode) {
        let measuringLineNode = createLineNode(fromNode: fromNode, toNode: toNode)
        measuringLineNode.name = "MeasuringLine"
        sceneView.scene.rootNode.addChildNode(measuringLineNode)
        objects.append(measuringLineNode)
        
        let dist = fromNode.position.distanceTo(toNode.position)
        let cm = dist*100
        let measurementValue = String(format: "%.2f", cm)
        distanceLabel.text = "Distance: \(measurementValue) cm"
        
    }
    
    func updateMeasuringNodes() {
        guard measuringNodes.count >  1 else {
            return
        }
        let firstNode = measuringNodes[0]
        let secondNode = measuringNodes[1]
        
        let showMeasuring = self.measuringNodes.count == 2
        distanceLabel.isHidden = !showMeasuring
        
        if showMeasuring {
            measure(fromNode: firstNode, toNode: secondNode)
        } else if measuringNodes.count > 2 {
            firstNode.removeFromParentNode()
            secondNode.removeFromParentNode()
            measuringNodes.removeFirst(2)
            
            for node in sceneView.scene.rootNode.childNodes {
                if node.name == "MeasuringLine" {
                    node.removeFromParentNode()
                }
            }
            
        }
    }
    
    func updateTrackingInfo() {
        
        guard let frame = sceneView.session.currentFrame else {
            return
        }
        switch frame.camera.trackingState {
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                trackingInfo.text = "Limited Tracking: Excessive Motion"
            case .insufficientFeatures:
                trackingInfo.text = "Limited Tracking: Insufficient Details"
            default:
                trackingInfo.text = "Limited Tracking"
            }
        default:
            trackingInfo.text = ""
        }
        
        guard let lightEstimate = frame.lightEstimate?.ambientIntensity else {
            return
        }
        
        if lightEstimate < 100 {
            trackingInfo.text = "Limited Tracking: Too Dark"
        }
    }
    
}

extension HomeViewController: SCNPhysicsContactDelegate
{
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        let contactMask = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
        
        if (contactMask == (collisionCatBottom | collisionCatCube)) {
            if (contact.nodeA.physicsBody?.categoryBitMask == collisionCatBottom) {
                contact.nodeB.removeFromParentNode()
            } else {
                contact.nodeA.removeFromParentNode()
            }
        }
    }
}

extension HomeViewController: ARSCNViewDelegate {
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        
        showMessage(error.localizedDescription, label: messageLabel, seconds: 2)
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        
        showMessage("Session interuppted", label: messageLabel, seconds: 2)
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        
        showMessage("Session resumed", label: messageLabel, seconds: 2)
        removeAllObjects()
        runSession()
        
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        DispatchQueue.main.async {
            self.updateTrackingInfo()
        }
        
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                #if DEBUG
                    let planeNode = createPlaneNode(center: planeAnchor.center, extent: planeAnchor.extent)
                    node.addChildNode(planeNode)
                #endif
            } else {
                switch self.currentMode {
                case .none:
                    break
                case .placeObject(let name):
                    let modelClone = SCNScene(named: name)!.rootNode.clone()
                    self.objects.append(modelClone)
                    node.addChildNode(modelClone)
                    
                    let constraint = SCNLookAtConstraint(target: self.sceneView.pointOfView)
                    
                    // Keep the rotation on the horizon
                    constraint.isGimbalLockEnabled = true
                    
                    // Slow the constraint down a bit
                    constraint.influenceFactor = 0.01
                    
                    // Finally add the constraint to the node
                    modelClone.constraints = [constraint]
                    
                    let spotLight = SCNLight()
                    spotLight.type = SCNLight.LightType.spot
                    spotLight.spotInnerAngle = 45
                    spotLight.spotOuterAngle = 45
                    modelClone.light = spotLight
                    
                case .measure:
                    let spehereNode = createSphereNode(radius: 0.02)
                    self.objects.append(spehereNode)
                    node.addChildNode(spehereNode)
                    self.measuringNodes.append(node)
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                updatePlaneNode(node.childNodes[0], center: planeAnchor.center, extent: planeAnchor.extent)
            } else {
                self.updateMeasuringNodes()
            }
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        removeChildren(inNode: node)
    }
    
}
