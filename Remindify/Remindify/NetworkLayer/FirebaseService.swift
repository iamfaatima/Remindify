import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()

    private init() {
        // Check if Firebase is not already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    var currentUser: User? {
            return Auth.auth().currentUser
        }

        func changeUserPassword(user: User, newPassword: String, completion: @escaping (Error?) -> Void) {
            user.updatePassword(to: newPassword) { error in
                completion(error)
            }
        }

    enum FirebaseError: Error {
        case userNotFound
    }
    
    func getCurrentUser(completion: @escaping (User?) -> Void) {
            if let user = Auth.auth().currentUser {
                completion(user)
            } else {
                completion(nil)
            }
        }
    
    func signInWithEmail(_ email: String, password: String, completion: @escaping (Result<User?, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            if let user = authResult?.user {
                completion(.success(user))
            } else if let error = error {
                completion(.failure(error))
            }
        }
    }
    
    func createUserWithEmail(_ name: String, email: String, password: String, completion: @escaping (Result<User?, Error>) -> Void) {
           Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
               if let user = authResult?.user {
                   // Successfully created the user, now save the user's name
                   let changeRequest = user.createProfileChangeRequest()
                   changeRequest.displayName = name
                   changeRequest.photoURL = nil

                   // Commit the changes to the user's profile
                   changeRequest.commitChanges { error in
                       if let error = error {
                           completion(.failure(error))
                       } else {
                           completion(.success(user))
                       }
                   }
               } else if let error = error {
                   completion(.failure(error))
               }
           }
       }
    
    func checkUserAuthentication(completion: @escaping (Bool) -> Void) {
            if Auth.auth().currentUser == nil {
                completion(false)
            } else {
                completion(true)
            }
        }

    func signOut(completion: @escaping (Bool, Error?) -> Void) {
            do {
                try Auth.auth().signOut()
                completion(true, nil)
            } catch {
                print("Error while signing out: \(error)")
                completion(false, error)
            }
        }

        func reauthenticateUser(with credential: AuthCredential, completion: @escaping (Error?) -> Void) {
            guard let user = Auth.auth().currentUser else {
                // Handle the error or show a relevant message
                completion(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not found"]))
                return
            }

            user.reauthenticate(with: credential) { _, error in
                completion(error)
            }
        }

    
    func loadReminders(completion: @escaping (Result<[ReminderModel], Error>) -> Void) {
            var reminders: [ReminderModel] = []

            if let user = Auth.auth().currentUser {
                let ownerId = user.uid  // Get the current user's UID

                db.collection("reminders")
                    .whereField("ownerId", isEqualTo: ownerId)  // Filter reminders by owner ID
                    .order(by: "Date", descending: true)
                    .addSnapshotListener { (querySnapshot, error) in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            reminders = []

                            if let snapshotDocuments = querySnapshot?.documents {
                                for document in snapshotDocuments {
                                    let data = document.data()
                                    if let title = data["Title"] as? String {
                                        let documentID = document.documentID
                                        let newReminder = ReminderModel(
                                            title: title,
                                            description: data["Description"] as! String,
                                            date: data["Date"] as? String,
                                            documentID: documentID, ownerId: ownerId)
                                        reminders.append(newReminder)
                                    } else {
                                        print("Error: Missing 'Title' in document")
                                    }
                                }
                                completion(.success(reminders))
                            } else {
                                print("Error: No documents found")
                                completion(.success([]))
                            }
                        }
                    }
            }
        }
    
    
    func addReminder(_ reminder: ReminderModel, completion: @escaping (Error?) -> Void) {
            if let user = Auth.auth().currentUser {
                let ownerId = user.uid

                var reminderData = [
                    "Title": reminder.title ?? "",
                    "Description": reminder.description ?? "",
                    "Date": reminder.date ?? "",
                    "ownerId": ownerId
                ]

                // Additional fields can be added as needed

                // Add the reminder to Firestore
                db.collection("reminders").addDocument(data: reminderData, completion: completion)
            }
        }
    
    func updateReminder(_ reminder: ReminderModel, completion: @escaping (Error?) -> Void) {
            guard let documentID = reminder.documentID else {
                // Handle the case where the reminder doesn't have a document ID
                completion(NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid document ID"]))
                return
            }

            let reminderData: [String: Any] = [
                "Title": reminder.title,
                "Description": reminder.description,
                "Date": reminder.date
            ]

            db.collection("reminders").document(documentID).updateData(reminderData) { error in
                completion(error)
            }
        }
    
    func updateDisplayName(_ displayName: String, completion: @escaping (Error?) -> Void) {
            if let user = Auth.auth().currentUser {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                changeRequest.commitChanges { error in
                    completion(error)
                }
            } else {
                completion(NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            }
        }

    func uploadProfileImage(image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
            let storage = Storage.storage()
            let storageRef = storage.reference().child("images/\(UUID().uuidString).jpg")

            if let imageData = image.jpegData(compressionQuality: 0.8) {
                storageRef.putData(imageData, metadata: nil) { (metadata, error) in
                    guard error == nil else {
                        completion(.failure(error!))
                        return
                    }

                    storageRef.downloadURL { (url, error) in
                        guard let downloadURL = url else {
                            completion(.failure(error ?? NSError(domain: "FirebaseService", code: 0, userInfo: nil)))
                            return
                        }

                        completion(.success(downloadURL))
                    }
                }
            }
        }

        func updateUserProfilePhotoURL(_ url: URL, completion: @escaping (Error?) -> Void) {
            if let user = Auth.auth().currentUser {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.photoURL = url
                changeRequest.commitChanges { error in
                    completion(error)
                }
            } else {
                let error = NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                completion(error)
            }
        }
    
    func getCurrentUserPhotoURL(completion: @escaping (Result<URL, Error>) -> Void) {
        if let user = Auth.auth().currentUser, let photoURL = user.photoURL {
            completion(.success(photoURL))
        } else {
            let error = NSError(domain: "FirebaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not logged in or photoURL is not available"])
            completion(.failure(error))
        }
    }

    func deleteReminder(documentID: String, completion: @escaping (Error?) -> Void) {
            let reminderRef = Firestore.firestore().collection("reminders").document(documentID)
            
            reminderRef.delete { error in
                completion(error)
            }
        }

//    func deleteReminder(_ reminder: ReminderModel, completion: @escaping (Result<Void, Error>, [ReminderModel]) -> Void) {
//           guard let ownerId = reminder.ownerId, let documentId = reminder.documentID else {
//               // Handle missing ownerId or documentId
//               completion(.failure(NSError(domain: "FirebaseService", code: 400, userInfo: nil)), [])
//               return
//           }
//
//           // Update Firestore
//           db.collection("reminders").document(documentId).delete { error in
//               if let error = error {
//                   print("Error deleting document: \(error)")
//                   completion(.failure(error), [])
//               } else {
//                   print("Document successfully deleted!")
//
//                   // Obtain the notification identifier
//                   let notificationIdentifier = "Reminder_\(documentId)"
//                   // Remove the local notification with the obtained identifier
//                   UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
//
//                   // Firestore will trigger the snapshot listener, updating the table view
//                   completion(.success(()), [])
//               }
//               self.loadReminders()
//           }
//       }
}
