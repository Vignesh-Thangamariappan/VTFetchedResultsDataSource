//
//  VTCollectionViewDelegate.swift
//  VTFetchedResultsDataSource
//
//  Created by Vignesh on 20/10/21.
//

import UIKit

protocol FRCCollectionViewDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView
    func reloadView()
}

protocol BatchUpdate {
    associatedtype EntityType
    var deleted: [EntityType] { get set }
    var inserted: [EntityType] { get set }
    var moved: [(from: EntityType, to: EntityType)] { get set }
    var updated: [EntityType] { get set }
}

struct SectionUpdates {
    typealias EntityType = Int
    var inserted: [Int] = []
    var updated: [Int] = []
    var deleted: [Int] = []
    var moved: [(from: Int, to: Int)] = []
}

struct RowUpdates {
    typealias EntityType = IndexPath
    var inserted: [IndexPath] = []
    var updated: [IndexPath] = []
    var deleted: [IndexPath] = []
    var moved: [(from: IndexPath, to: IndexPath)] = []
}


extension Array {
    var isNotEmpty: Bool {
        !isEmpty
    }
}
