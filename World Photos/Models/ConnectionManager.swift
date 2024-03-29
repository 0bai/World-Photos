import Foundation
import CoreData
import UIKit
import MapKit

protocol ConnectionDelegate{
    func listRetrieved(size: Int)
    func serverError(error: String, details: String)
}

class ConnectionManager {
    
    static var delegate:ConnectionDelegate!
    
    internal static var dataController: DataController!
    
    static func getPhotoAlbum(pinID: NSManagedObjectID, coordinates: CLLocationCoordinate2D){
        let url = FlickrAPI(latitude: coordinates.latitude, longitude: coordinates.longitude).getURL()
        fireRequest(url: url, headers: nil, body: nil){
            data, response, error in
            let json: PhotosJSON = decode(data: data, type: PhotosJSON.self) as! PhotosJSON
            let photos: Photos = json.photos
            delegate.listRetrieved(size: photos.photo.count)
            DispatchQueue.global(qos: .background).async {
                getPhotos(photos, pinID: pinID)
            }
        }
    }
    
    static func getPhotos(_ photos: Photos, pinID: NSManagedObjectID) {
        
        var pin: Pin!
        
        dataController.backgroundContext.perform {
            pin = dataController.backgroundContext.object(with: pinID) as? Pin
        }
        
        photos.photo.forEach{
            photoJSON in
            let photoURL = PhotoURL(farmID: photoJSON.farm, serverID: photoJSON.server, photoID: photoJSON.id, secret: photoJSON.secret).getURL()
            
            fireRequest(url: photoURL, headers: nil, body: nil){
                data, response, error in
                
                dataController.backgroundContext.performAndWait {
                    let photo = Photo(context: dataController.backgroundContext)
                    photo.image = data
                    photo.pin = pin
                    photo.created = Date()
                    
                    if dataController.backgroundContext.hasChanges{
                        sleep(1)
                        try? dataController.backgroundContext.save()
                    }
                }
            }
        }
    }
}







