//
//  CoreDataManager.swift
//
//  2026/3/27.
//

import CoreData

open class CoreDataManager {
    /// 单例
    public static let shared = CoreDataManager()

    /// CoreData 文件名
    public var coreDataName = "CoredataName"

    public lazy var persistentContainer: NSPersistentContainer = {
        let objectModel = loadManagedObjectModel(named: coreDataName)
        let container = NSPersistentContainer(name: coreDataName, managedObjectModel: objectModel)

        container.loadPersistentStores { storeDescription, error in
            if let error {
                assertionFailure("Cannot load core data store: \(storeDescription.url?.absoluteString ?? "unknown"). Error: \(error)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    public lazy var managerContext: NSManagedObjectContext = {
        persistentContainer.viewContext
    }()

    public lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()

    public func saveContent(_ moc: NSManagedObjectContext) {
        moc.performAndWait {
            guard moc.hasChanges else {
                return
            }
            do {
                try moc.save()
            } catch {
                assertionFailure("Cannot save core data. Error: \(error)")
            }
        }

        if let parent = moc.parent {
            saveContent(parent)
        }
    }

    public func clearStorage(entityName: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs

        do {
            let result = try managerContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
            if let objectIDs = result?.result as? [NSManagedObjectID], !objectIDs.isEmpty {
                let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [managerContext, backgroundContext])
            }
        } catch {
            assertionFailure("Cannot delete local storage for: \(entityName). Reason: \(error)")
        }
    }

    private func loadManagedObjectModel(named name: String) -> NSManagedObjectModel {
        guard let modelURL = Bundle.main.url(forResource: name, withExtension: "momd") else {
            fatalError("Core Data model file '\(name).momd' not found in main bundle.")
        }
        guard let objectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to initialize NSManagedObjectModel from url: \(modelURL).")
        }
        return objectModel
    }
}
