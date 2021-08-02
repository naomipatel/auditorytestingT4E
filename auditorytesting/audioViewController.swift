//
//  audioViewController.swift
//  auditorytesting
//
//  Created by Adam Krekorian on 4/1/21.
//  Copyright © 2021 Adam Krekorian. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class audioViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate, AVAudioRecorderDelegate, UITextFieldDelegate {
    
    let NUMBER_OF_PRELOADED_SOUNDS = 6
    let defaults = UserDefaults.standard
    
    var player:AVAudioPlayer?
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var url: URL?
    var playing: Bool = false

    var queue = DispatchQueue(label: "seq.queue", qos: DispatchQoS.default)
    var item: DispatchWorkItem?
  
    
    var soundNames: [String] = ["Bell Ringing", "Clapping", "Horn", "Birds Chirping","Car Engine", "Dog Barking"]
    var sounds: [String] = ["sounds/bell.mp3", "sounds/clap.mp3", "sounds/train-horn.wav","sounds/birds.mp3","sounds/car-rev.mp3","sounds/bark.wav"]
    
    var soundData: [NSManagedObject] = []
    
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    func cancelPlaying() {
        player!.stop()
        player = nil
        if (directButton.titleLabel?.text == "Tap to Stop" || directButton.titleLabel?.text == "Tap to Pause") {
            directButton.setTitle("Play Sequence", for: .normal)
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player_static: AVAudioPlayer, successfully flag: Bool) {
        if (flag == true) { cancelPlaying() }
    }
    
    
    
    func playSound(_ panVal: Float) {
        let selectRow = tableView.indexPathForSelectedRow?.row
        
        if (tableView.indexPathForSelectedRow == nil){
            return
        }
        
        let tempPath = "\(sounds[selectRow!])"
        
        let url: URL?
        if (selectRow! >= NUMBER_OF_PRELOADED_SOUNDS) {
            url = URL(string: tempPath)
        } else {
            url = Bundle.main.url(forResource: tempPath, withExtension: nil)
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            try url?.checkResourceIsReachable()
            
            
            player = try AVAudioPlayer(contentsOf: url!)
            player?.delegate = self
            player!.prepareToPlay()
            player!.pan = panVal
            player!.play()
            sleep(UInt32(5))
            player!.stop()
            
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    
    @IBOutlet weak var directButton: UIButton!
    
    @IBAction func playDirect(_ sender: UIButton) {
        
        let selectRow = tableView.indexPathForSelectedRow?.row ?? nil
        
        if (selectRow == nil) {
           let alert = UIAlertController(title: "No Sound Selected", message: "Please select a sound to play", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))

            self.present(alert, animated: true)
        } else {
            if (!playing) {
            
                    let panVals = [-1.0 , 1.0 , -1.0 , 1.0]
                    queue.async() {}
            
                    item = DispatchWorkItem { [weak self] in
                        for i in 0...3 where self?.item?.isCancelled == false { // false
                            let semaphore = DispatchSemaphore(value: 0)
                            semaphore.signal()
            
                            self?.playSound(Float(panVals[i])) // no float
                            sleep(10) //5
                            semaphore.wait()
                        }
                        DispatchQueue.main.async {
                            self?.playing = false
                            let button = sender
                            button.setTitle("Play Sequence", for: .normal)
                        }
                        self?.item = nil
                    }
                    let button = sender
                    button.setTitle("Tap to Pause", for: .normal)
                    playing = true
            
                    queue.async(execute: item!)
                }
                else {
                    let button = sender
                    button.setTitle("Play Sequence", for: .normal)
                    player!.stop()
                    item?.cancel()
                    playing = false
                }
        }
    }
    
    func alertRecording() {
        let alert = UIAlertController(title: "Recording in Progress", message: "Please finish recording before playing back a sound.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alert, animated: true)
        return
    }

    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
            else {
                return
            }

        let managedContext = appDelegate.persistentContainer.viewContext

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Sound")

        do {
            soundData = try managedContext.fetch(fetchRequest)
            if (soundData.count) <= 0 { return }
            for sound in soundData {
                print(soundData.count)
                sounds.append(sound.value(forKeyPath: "path") as! String)
                soundNames.append(sound.value(forKeyPath: "name") as! String)
            }
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        print("table view sounds count: \(sounds.count)")
        return sounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customSoundCell") as! customSoundCell
        cell.soundId?.text = soundNames[indexPath.row]
        
        print("cell name: \(cell.soundId.text ?? "default")")
        
        return cell
    }
    
    @IBAction func goToSequence(_ sender: UIButton) {
        if audioRecorder != nil { alertRecording() }
        self.performSegue(withIdentifier: "segueSequence", sender: self)
        if player != nil {
            cancelPlaying()
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "segueSequence") {
            let selectRow = tableView.indexPathForSelectedRow?.row ?? nil
            let controller = segue.destination as! sequenceViewController

            if (selectRow != nil) {
                controller.currentInd = selectRow!
                controller.currentSoundName =  soundNames[selectRow!]
                controller.currentSoundPath =  sounds[selectRow!]
            } else {
               let alert = UIAlertController(title: "No Sound Selected", message: "Please select a sound to create a sequence", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))

                self.present(alert, animated: true)
            }
        }
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
    override open var shouldAutorotate: Bool {
       return false
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
       return .portrait
    }

    
    func applicationWillTerminate(_ application: UIApplication) {
        print("terminating")
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
            else {
                return
            }

        let managedContext = appDelegate.persistentContainer.viewContext
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
    }

}

    
