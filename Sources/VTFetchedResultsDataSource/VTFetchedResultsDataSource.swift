import UIKit
import CoreData

class VTFetchedResultsCollectionViewDataSource<FetchRequestResult: NSFetchRequestResult>: NSObject, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    let fetchedResultsController: NSFetchedResultsController<FetchRequestResult>
    weak var collectionView: UICollectionView?
    weak var delegate: FRCCollectionViewDelegate?
    
    var rowUpdates = RowUpdates()
    var sectionUpdates = SectionUpdates()
    
    private var operationQueue = OperationQueue()
    
    init(fetchRequest: NSFetchRequest<FetchRequestResult>, context: NSManagedObjectContext, sectionNameKeyPath: String?) {
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil
        )
        super.init()
        fetchedResultsController.delegate = self
    }
    
    func performFetch() throws {
        try fetchedResultsController.performFetch()
    }
    
    open func object(at indexPath: IndexPath) -> FetchRequestResult {
        return fetchedResultsController.object(at: indexPath)
    }
    
    open func objects(inSection section: Int) -> [FetchRequestResult] {
        return fetchedResultsController.sections?[section].objects as? [FetchRequestResult] ?? []
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let numberOfSections = fetchedResultsController.sections?.count, numberOfSections > 0 else {
            return 1
        }
        return numberOfSections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections, sections.isNotEmpty else { return 0 }
        
        return sections[section].numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let delegate = delegate {
            return delegate.collectionView(collectionView, cellForItemAt: indexPath)
        } else {
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let delegate = delegate else {
            return UICollectionReusableView()
        }
        return delegate.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        operationQueue = OperationQueue()
        operationQueue.qualityOfService = .userInteractive
        clearUpdates()
    }
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange sectionInfo: NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for type: NSFetchedResultsChangeType
    ) {
        
        switch type {
        case .insert:
            sectionUpdates.inserted.append(sectionIndex)
        case .delete:
            sectionUpdates.deleted.append(sectionIndex)
        case .update:
            sectionUpdates.updated.append(sectionIndex)
        case .move:
            assertionFailure("MOVE SECTION is not handled")
        @unknown default:
            break
        }
    }
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        switch type {
        case .insert:
            guard let indexPath = newIndexPath else { break }
            rowUpdates.inserted.append(indexPath)
        case .delete:
            guard let indexPath = indexPath else { break }
            
            rowUpdates.deleted.append(indexPath)
        case .update:
            guard let indexPath = indexPath else { break }
            
            rowUpdates.updated.append(indexPath)
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
            
            rowUpdates.moved.append((indexPath, newIndexPath))
        @unknown default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async {
            self.collectionView?.performBatchUpdates({
                self.performBatchUpdatesForSections(self.sectionUpdates)
                self.performBatchUpdatesForRows(self.rowUpdates)
            }, completion: { _ in
                self.delegate?.reloadView()
            })
        }
    }
    
    func clearUpdates() {
        sectionUpdates = SectionUpdates()
        rowUpdates = RowUpdates()
    }
    
    private func performBatchUpdatesForSections(_ updates: SectionUpdates) {
        
        self.collectionView?.insertSections(IndexSet(updates.inserted))
        self.collectionView?.deleteSections(IndexSet(updates.deleted))
        self.collectionView?.reloadSections(IndexSet(updates.updated))
        
        for moveSection in updates.moved {
            self.collectionView?.deleteSections(IndexSet(integer: moveSection.from))
            self.collectionView?.insertSections(IndexSet(integer: moveSection.to))
        }
    }
    
    private func performBatchUpdatesForRows(_ updates: RowUpdates) {
        
        self.collectionView?.insertItems(at: updates.inserted)
        
        self.collectionView?.deleteItems(at: updates.deleted)
        
        self.collectionView?.reloadItems(at: updates.updated)
        
        for moveRow in updates.moved {
            let indexPathToRemove = moveRow.from
            let indexPathToInsert = moveRow.to
            self.collectionView?.deleteItems(at: [indexPathToRemove])
            self.collectionView?.insertItems(at: [indexPathToInsert])
        }
    }
}
