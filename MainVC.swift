//
//  MainVC.swift
//  engelsizDuraklarPrototip1
//
//  Created by Ibrahim Gok on 9.04.2023.
//

// Gerekli kütüphanelerin tanımlanması.
import UIKit
import Speech
import AVFoundation
import FirebaseFirestore
import FirebaseDatabase

class MainVC: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet weak var startButton: UIButton!
    
    // Değişknelerin tanımlanması
    var BusNumber = Int()
    var TimeLeft = Int()
    var EmptySeats = Int()
    
    let audiEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale.init(identifier: "tr-TR")) // Türkçe ses tanıma için obje tanımlanması
    let request = SFSpeechAudioBufferRecognitionRequest() // ses tanıma için gerekli isteğin oluşturulması
    var task: SFSpeechRecognitionTask! // saptanması gereken ses komutu için obje tanımlanması
    var isStart: Bool = false
    
    // sesli anlatım için obje tanımlanması
    let synthesizer = AVSpeechSynthesizer()
    var textToSpeak = String()
    
    // veri tabanının tanımlanması
    let database = Database.database(url: "https://engelsiz-duraklar---prototip-1-default-rtdb.europe-west1.firebasedatabase.app").reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // izinlerin istenmesi
        requestPermission()
        
        // Veri tabanından verilerin çekilmesi
        database.child("EmptySeats").observeSingleEvent(of: .value, with: { snapshot in
            guard let value1 = snapshot.value as? Int else {
                return
            }
            self.EmptySeats = value1
        })
        database.child("TimeLeft").observeSingleEvent(of: .value, with: { snapshot in
            guard let value2 = snapshot.value as? Int else {
                return
            }
            self.TimeLeft = value2
        })
        database.child("BusNumber").observeSingleEvent(of: .value, with: { snapshot in
            guard let value3 = snapshot.value as? Int else {
                return
            }
            self.BusNumber = value3
        })
    }
    
    @IBAction func startButtonPressed(_ sender: Any) {
        
        
            isStart = !isStart
            if isStart {
                startSpeechRecognition()
                startButton.setTitle("Bitir", for: .normal)
            }
    }
    // Bilgi al butonunun çalıştırılması
    @IBAction func getInfo(_ sender: Any) {
       
        textToSpeak = "\(BusNumber) numaralı otobüs, \(TimeLeft) dakika sonra durağa ulaşacaktır."
        let utterance = AVSpeechUtterance(string: textToSpeak)
        utterance.volume = 1
        synthesizer.speak(utterance)
        
        /*
        let firestoredatabase = Firestore.firestore()
        
        firestoredatabase.collection("BusInfo").addSnapshotListener { [self] snapshot, error in
            
            if error != nil {
                print(error?.localizedDescription)
            } else {
                if snapshot?.isEmpty != true && snapshot != nil {
                    
                    for document in snapshot!.documents {
                        
                        if let busNumber_data = document.get("Number") as? Int {
                            BusNumber = busNumber_data
                        }
                        
                        if let timeLeft_data = document.get("TimeLeft") as? Int {
                            TimeLeft = timeLeft_data
                        }
                        
                        if let emptySeats_data = document.get("EmptySeats") as? Int {
                            EmptySeats = emptySeats_data
                        }
                        textToSpeak = "\(BusNumber) numaralı otobüs, \(TimeLeft) dakika sonra durağa ulaşacaktır."
                        let utterance = AVSpeechUtterance(string: textToSpeak)
                        synthesizer.speak(utterance)
                    }
                }
            }
            
        } */
    }
    
    // Aplikasyonun kullanıcıyı dinlemesi için gerekli fonksiyon
    func startSpeechRecognition() {
        
        let node = audiEngine.inputNode
        node.reset()
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { (buffer, _) in
            self.request.append(buffer)
        }
        // ses dinleme için gerekli ayarların yapılması
        audiEngine.prepare()
        do {
            try audiEngine.start()
        } catch let error {
           // alertView(message: "error")
        }
        guard let myRecognition = SFSpeechRecognizer() else {
           // self.alertView(message: "Recognition is not allowed on your local")
            return
        }
        if !myRecognition.isAvailable {
            //self.alertView(message: "Recognition is free")
        }
        
        // Kullanıcının sesinin dinlenmesi
        task = speechRecognizer?.recognitionTask(with: request, resultHandler: { response, error in
            guard let response = response else {
                if error != nil {
                  //  self.alertView(message: "Error")
                } else {
                  //  self.alertView(message: "Problem in giving the response")
                }
                return
            }
            
            let message = response.bestTranscription.formattedString
            print(message)
            var lastString: String = ""
            for segment in response.bestTranscription.segments {
                let indexTo = message.index(message.startIndex, offsetBy: segment.substringRange.location)
                lastString = String(message[indexTo...])
            }
            
            // Kullanıcının komutunun algılanması
            if lastString == "iki" || lastString == "numara" {
                
                self.cancelSpeechRecognition()
                self.SpeechTwo()
                self.isStart = false
                self.startButton.setTitle("Otobüs Seç", for: .normal)
            
               /* let firestoredatabase = Firestore.firestore()
                firestoredatabase.collection("BusInfo").addSnapshotListener { [self] snapshot, error in
                    
                    if error != nil {
                        print(error?.localizedDescription)
                    } else {
                        if snapshot?.isEmpty != true && snapshot != nil {
                            
                            for document in snapshot!.documents {
                                
                                if 2 == document.get("Number") as? Int {
                                    if let timeLeft_data = document.get("TimeLeft") as? Int {
                                        TimeLeft = timeLeft_data
                                    }
                                    
                                    if let emptySeats_data = document.get("EmptySeats") as? Int {
                                        EmptySeats = emptySeats_data
                                    }
                                    textToSpeak = "2 numaralı otobüs, \(TimeLeft) dakika sonra durağa ulaşacaktır. \(EmptySeats) adet boş yer bulunmaktadır."
                                    let utterance = AVSpeechUtterance(string: textToSpeak)
                                    synthesizer.speak(utterance)
                                    cancelSpeechRecognition()
                                    isStart = false
                                    startButton.setTitle("Otobüs Seç", for: .normal)
                                    
                                }
                            }
                        }
                    }
                    
                } */
            }
            
        })
    }
    
    // Kullanıcıya bilginin sesli olarak iletilmesi
    func SpeechTwo() {
        task.finish()
        task.cancel()
        task =  nil
        request.endAudio()
        audiEngine.stop()
        audiEngine.inputNode.removeTap(onBus: 0)
        self.textToSpeak = "\(BusNumber) numaralı otobüs, \(self.TimeLeft) dakika sonra durağa ulaşacaktır. \(self.EmptySeats) adet boş yer bulunmaktadır."
        let utterance = AVSpeechUtterance(string: self.textToSpeak)
        utterance.volume = 1
        synthesizer.speak(utterance)
    }

    // Ses ile komut bekleme fonksiyonunun devre dışı bırakılması
    func cancelSpeechRecognition() {
        
    }

    // Ses ile komut bekleme ve sesli anlatım fonksiyonlarının gerçekleştirilebilmesi için kullanıcının cihazından gerekli izinlerin alınması.
    func requestPermission() {
        self.startButton.isEnabled = false
        SFSpeechRecognizer.requestAuthorization { (authState) in
            OperationQueue.main.addOperation {
                if authState == .authorized {
                    print("Accepted")
                    self.startButton.isEnabled = true
                } else if authState == .denied {
                    //self.alertView(message: "User denied the permission.")
                }
                else if authState == .notDetermined {
                    //self.alertView(message: "in user phone there is no speech recognition")
                }
                else if authState == .restricted {
                   // self.alertView(message: "user has been restricted for using the speech recognition")
                }
            }
        }
    }
    
   /* func alertView(message: String) {
        let controller = UIAlertController.init(title: "Error!", message: "OK", preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            controller.dismiss(animated: true, completion: nil)
        }))
        self.present(controller,animated: true,completion: nil)
   } */
    
    
}
