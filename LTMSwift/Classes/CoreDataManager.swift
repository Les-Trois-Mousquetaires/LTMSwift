//
//  CoreDataManager.swift
//  LTMSwift
//
//  Created by 柯南 on 2023/2/17.
//

import CoreData

open class CoreDataManager{
    /// 单例
    public static let share = CoreDataManager()
    /// 唯一标识
    let identifier = "io.ltm.coredata"
    /// CoreData 文件名
    public var coreDataName = "CoredataName"
    
    public lazy var persistenContainer: NSPersistentContainer = {
        let dataKitBundle = Bundle.main
        let modelUrl = Bundle.main.url(forResource: self.coreDataName, withExtension: "momd")!
        let managerObjectModel = NSManagedObjectModel(contentsOf: modelUrl)!
        let container = NSPersistentContainer(name: self.coreDataName, managedObjectModel: managerObjectModel)
        container.loadPersistentStores { (storeDescription, error) in
            guard let err = error else {
                return
            }
            print(storeDescription)
            fatalError("Cannot load core data store.")
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    public lazy var managerContext: NSManagedObjectContext = {
        return self.persistenContainer.viewContext
    }()
    
    public lazy var backgroundContext: NSManagedObjectContext = {
        let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childContext.parent = managerContext
        
        return childContext
    }()
    
    public func saveContent(_ moc: NSManagedObjectContext) {
        guard moc.hasChanges else {
            return
        }
        do {
            try moc.save()
        } catch let error as NSError {
            fatalError("Cannot save core data. Error: \(error), \(error.userInfo)")
        }
    }
    
    public func clearStorange(entityName: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try managerContext.execute(batchDeleteRequest)
        } catch let error as NSError {
            print("Cannot delete local storage for: \(entityName).\nReason: \(error.localizedDescription)")
        }
    }
}
