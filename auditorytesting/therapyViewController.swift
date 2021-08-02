//
//  therapyViewController.swift
//  auditorytesting
//
//  Created by Naomi Patel on 6/9/21.
//  Copyright © 2021 Adam Krekorian. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class therapyViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate, AVAudioRecorderDelegate, UITextFieldDelegate, NSFetchedResultsControllerDelegate {
    
    let NUMBER_OF_PRELOADED_SOUNDS = 6
    let defaults = UserDefaults.standard
    
    var player:AVAudioPlayer?
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    var soundNames: [String] = ["Bell Ringing", "Clapping", "Horn", "Birds Chirping","Car Engine", "Dog Barking"]
    var sounds: [String] = ["sounds/bell.mp3", "sounds/clap.mp3", "sounds/train-horn.wav","sounds/birds.mp3","sounds/car-rev.mp3","sounds/bark.wav"]
    
    var soundData: [NSManagedObject] = []
    
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var bothButton: UIButton!
    
    
    func cancelPlaying() {
        player!.stop()
        player = nil
        if (leftButton.titleLabel?.text == "Tap to Stop") {
            leftButton.setTitle("Play Left", for: .normal)
        }
        if (rightButton.titleLabel?.text == "Tap to Stop") {
            rightButton.setTitle("Play Right", for: .normal)
        }
        if(bothButton.titleLabel?.text == "Tap to Stop"){
            bothButton.setTitle("Play Both", for: .normal)
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player_static: AVAudioPlayer, successfully flag: Bool) {
        if (flag == true) { cancelPlaying() }
    }
    
    func playSound(_ sender: Any, _ panVal: Float) {
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
            player!.numberOfLoops =  -1
            player!.play()
            
            let button = sender as! UIButton
            button.setTitle("Tap to Stop", for: .normal)
        
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func soundSelectAlert() {
        let selectRow = tableView.indexPathForSelectedRow?.row ?? nil
        
        if (selectRow == nil) {
           let alert = UIAlertController(title: "No Sound Selected", message: "Please select a sound to play", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))

            self.present(alert, animated: true)
        }
    }
    
    
        @IBAction func playLeft(_ sender: UIButton) {
            
            soundSelectAlert()
            
            if audioRecorder != nil { alertRecording() }
            let panVal: Float = -1.0;
            if player == nil || sender.titleLabel?.text == "Play Left" {
                playSound(sender, panVal)
                if (rightButton.titleLabel?.text == "Tap to Stop" && bothButton.titleLabel?.text == "Tap to Stop") {
                    rightButton.setTitle("Play Right", for: .normal)
                    bothButton.setTitle("Play Both", for: .normal)
                }
            } else {
                cancelPlaying()
            }
        }
        
        @IBAction func playRight(_ sender: UIButton) {
            
            soundSelectAlert()
            
            if audioRecorder != nil { alertRecording() }
            let panVal: Float = 1.0;
            if player == nil || sender.titleLabel?.text == "Play Right" {
                playSound(sender, panVal)
                if (leftButton.titleLabel?.text == "Tap to Stop" && bothButton.titleLabel?.text == "Tap to Stop") {
                    leftButton.setTitle("Play Left", for: .normal)
                    bothButton.setTitle("Play Both", for: .normal)
                }
            } else {
                cancelPlaying()
            }
        }
        
        @IBAction func playBoth(_ sender: UIButton) {
            
            soundSelectAlert()

            if audioRecorder != nil { alertRecording() }
            let panVal: Float = 0.0;
            if player == nil || sender.titleLabel?.text == "Play Both" {
                playSound(sender, panVal)
                if (leftButton.titleLabel?.text == "Tap to Stop" && rightButton.titleLabel?.text == "Tap to Stop") {
                    leftButton.setTitle("Play Left", for: .normal)
                    rightButton.setTitle("Play Right", for: .normal)
                }
            } else {
                cancelPlaying()
            }
        }
    
    func save(name: String, path: String) {

        guard let appDelegate =
        UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        let managedContext = appDelegate.persistentContainer.viewContext

        let entity = NSEntityDescription.entity(forEntityName: "Sound",
                                   in: managedContext)!

        let sound = NSManagedObject(entity: entity,
                                   insertInto: managedContext)

        sound.setValue(name, forKeyPath: "name")
        sound.setValue(path, forKeyPath: "path")

        do {
            try managedContext.save()
            soundData.append(sound)
        } catch let error as NSError {
        print("Could not save. \(error), \(error.userInfo)")
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
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Sound")
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
            else {
                return
            }

        let managedContext = appDelegate.persistentContainer.viewContext
        
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
        
        tableView.reloadData()
       
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
        return sounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customSoundCell") as! customSoundCell
        
        cell.soundId?.text = soundNames[indexPath.row]
        print("cell name therapy: \(cell.soundId.text ?? "default")")
        return cell
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
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
