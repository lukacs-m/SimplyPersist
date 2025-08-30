import Testing
@testable import SimplyPersist
import SwiftData
import Foundation

@Model
final class TestEntity: @unchecked Sendable, Identifiable, Equatable, Hashable, Comparable {
    @Attribute(.unique) public private(set) var id: String
    public private(set) var comments: String
    public private(set) var name: String

    init(id: String, comments: String, name: String) {
        self.id = id
        self.comments = comments
        self.name = name
    }

    func update(_ newComments: String) {
        comments = newComments
    }

    static func < (lhs: TestEntity, rhs: TestEntity) -> Bool {
        lhs.id == rhs.id
    }
}

@Model
final class TestEntity2: @unchecked Sendable, Identifiable, Equatable, Hashable, Comparable {
    @Attribute(.unique) private(set) var id: String
    public private(set) var name: String

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    static func < (lhs: TestEntity2, rhs: TestEntity2) -> Bool {
        lhs.id == rhs.id
    }
}

extension TestEntity2 {
    static var mock: TestEntity2 {
        TestEntity2(id: UUID().uuidString, name: "Test Entity2")
    }
}

extension TestEntity {
    static var mock: TestEntity {
        TestEntity(id: UUID().uuidString, comments: "Test comment", name: "Test Entity")
    }
}

@Suite("SimplyPersist Integration Tests")
struct SimplyPersistTests {
    private var sut: PersistenceServicing
    private let dbURL: URL

    init() throws {
        // Create a unique temp SQLite file
        let tmpDir = FileManager.default.temporaryDirectory
        dbURL = tmpDir.appendingPathComponent("simplypersist-\(UUID().uuidString).sqlite")

        let config = ModelConfiguration(schema: Schema([TestEntity.self, TestEntity2.self]), url: dbURL, cloudKitDatabase: .none)
        // Use SQLite store at the temporary path
        sut = try PersistenceService(
            with: config
//                ModelConfiguration(
//                for: TestEntity.self, TestEntity2.self,
//                isStoredInMemoryOnly: true
//            )
        )
    }

    @Test func testSave() async throws {
        let model = TestEntity.mock
        try await sut.save(model)
        let entities: [TestEntity] = try await sut.fetchAll()

        #expect(entities.contains(model))
        #expect(entities.count == 1)
    }

    @Test func testMultipleSave() async throws {
        let models = [TestEntity.mock, TestEntity.mock, TestEntity.mock]
        try await sut.save(models)
        let entities: [TestEntity] = try await sut.fetchAll()

        #expect(entities.contains(models.first!))
        #expect(entities.contains(models.last!))
        #expect(entities.contains(models[1]))
        #expect(entities.count == 3)
    }

    @Test func testUpdate() async throws {
        let model = TestEntity.mock
        try await sut.save(model)

        let update = TestEntity(id: model.id, comments: "new comment", name: "new Title")
        try await sut.save(update)

        let updatedEntities: [TestEntity] = try await sut.fetchAll()
        #expect(updatedEntities.count == 1)
        #expect(updatedEntities.first?.name == "new Title")
    }

    @Test func testFetchAll() async throws {
        let entities = [TestEntity.mock, TestEntity.mock, TestEntity.mock]
        for e in entities { try await sut.save(e) }
        try await sut.save(TestEntity2.mock)

        let models: [TestEntity] = try await sut.fetchAll()
        let models2: [TestEntity2] = try await sut.fetchAll()

        #expect(models.count == 3)
        #expect(models2.count == 1)
    }

    @Test func testFetchFirst() async throws {
        let testEntity = TestEntity.mock
        try await sut.saveByBatch([TestEntity.mock, testEntity, TestEntity.mock])

        let id = testEntity.id
        let predicate = #Predicate<TestEntity> { $0.id == id }
        let result = try await sut.fetchFirst(predicate: predicate)

        #expect(result == testEntity)
    }

    @Test func testFetchWithID() async throws {
        let testEntity = TestEntity.mock
        try await sut.saveByBatch([TestEntity.mock, testEntity, TestEntity.mock])

        let result: TestEntity? = await sut.fetch(byIdentifier: testEntity.id)
        #expect(result == testEntity)
    }

    @Test func testFetchWithPredicate() async throws {
        // Given: Insert multiple entities
        let entities = [
            TestEntity(id: UUID().uuidString, comments: "", name: "This is the one"),
            TestEntity.mock,
            TestEntity.mock
        ]
        try await sut.saveByBatch(entities, batchSize: 10)

        // When: Fetch entities with a descriptor (filter by name)
        let targetName = entities[0].name
        let predicate = #Predicate<TestEntity> {
            $0.name == targetName
        }
        let fetchedEntities: [TestEntity] = try await sut.fetch(predicate: predicate)

        // Then: Ensure fetch returns only the matching entity
        #expect(fetchedEntities.count == 1)
        #expect(fetchedEntities.first?.id == entities[0].id)
    }

    @Test func testFetchWithDescriptor() async throws {
        // Given: Insert multiple entities
        let entities = [
            TestEntity(id: UUID().uuidString, comments: "", name: "This is the one"),
            TestEntity.mock,
            TestEntity.mock
        ]
        try await sut.saveByBatch(entities, batchSize: 10)

        // When: Fetch entities with a descriptor (filter by name)
        let targetName = entities[0].name
        let descriptor = FetchDescriptor<TestEntity>(predicate: #Predicate<TestEntity> {
            $0.name == targetName
        })
        let fetchedEntities: [TestEntity] = try await sut.fetch(using: descriptor)

        // Then: Ensure fetch returns only the matching entity
        #expect(fetchedEntities.count == 1)
        #expect(fetchedEntities.first?.id == entities[0].id)
    }

    @Test func testBatchFetch() async throws {
        var entities = [TestEntity]()
        for _ in 0..<10 { // tuned for speed
            entities.append(TestEntity.mock)
        }
        try await sut.saveByBatch(entities, batchSize: 1000)

        let descriptor = FetchDescriptor<TestEntity>()
        let models = try await sut.fetchByBatch(using: descriptor, batchSize: 2)

        #expect(models.count == entities.count)
        #expect(Set(models) == Set(entities))
    }

    @Test func testBatchSave() async throws {
        var entities = [TestEntity]()
        for _ in 0..<10_000 { // tuned for speed
            entities.append(TestEntity.mock)
        }
        let start = CFAbsoluteTimeGetCurrent()
        try await sut.saveByBatch(entities, batchSize: 5000)
        let diff = CFAbsoluteTimeGetCurrent() - start
        print("Took \(diff) seconds")
        let models: [TestEntity] = try await sut.fetchAll()
        
        #expect(models.count == entities.count)
        #expect(Set(models) == Set(entities))
    }

    @Test func testDeleteWithModel() async throws {
        let testEntity = TestEntity.mock
        try await sut.saveByBatch([TestEntity.mock, testEntity, TestEntity.mock])

        try await sut.delete(testEntity)
        let newResult: [TestEntity] = try await sut.fetchAll()

        #expect(newResult.count == 2)
        #expect(newResult.allSatisfy { $0.id != testEntity.id })
    }

    @Test func testDeletePredicate() async throws {
        let testEntity = TestEntity.mock
        try await sut.saveByBatch([TestEntity.mock, testEntity, TestEntity.mock])

        let id = testEntity.id
        let predicate = #Predicate<TestEntity> { $0.id == id }
        try await sut.delete(TestEntity.self, matching: predicate)

        let newResult: [TestEntity] = try await sut.fetchAll()
        #expect(newResult.count == 2)
        #expect(newResult.allSatisfy { $0.id != testEntity.id })
    }

    @Test func testDeleteFetchedEntities() async throws {
        // Given: Insert multiple entities
        let entities = [
            TestEntity(id: UUID().uuidString, comments: "", name: "This is the one"),
            TestEntity.mock,
            TestEntity.mock
        ]
        try await sut.saveByBatch(entities, batchSize: 10)

        // Fetch a subset for deletion
        let targetName = entities[0].name
        let descriptor = FetchDescriptor<TestEntity>(predicate: #Predicate<TestEntity> {
            $0.name == targetName
        })
        let toDelete: [TestEntity] = try await sut.fetch(using: descriptor)

        // When: Delete the fetched entities
        try await sut.delete(toDelete)
        
        // Then: Ensure the deleted entities are gone
        let remaining: [TestEntity] = try await sut.fetchAll()
        #expect(remaining.count == 2)
        #expect(remaining.contains(where: { $0.id == entities[0].id }) == false)
    }

    @Test func testDeleteAll() async throws {
        try await sut.saveByBatch([TestEntity.mock, TestEntity.mock, TestEntity.mock])
        try await sut.deleteAll(ofTypes: [TestEntity.self])

        let newResult: [TestEntity] = try await sut.fetchAll()
        #expect(newResult.isEmpty)
        try await sut.saveByBatch([TestEntity.mock, TestEntity.mock, TestEntity.mock])
        let entity2 = TestEntity2.mock
        try await sut.save(entity2)
        try await sut.deleteAll(ofTypes: [TestEntity.self])

        let newResult2: [TestEntity2] = try await sut.fetchAll()
        #expect(newResult2.count == 1)
        #expect(newResult2.first?.id == entity2.id)
    }

    @Test func testCount() async throws {
        try await sut.saveByBatch([TestEntity.mock, TestEntity.mock, TestEntity.mock])
        let count = try await sut.count(TestEntity.self)

        #expect(count == 3)
    }

    @Test func testEnumerate() async throws {
        let testEntity = TestEntity(id: "plop", comments: "", name: "This is it")
        try await sut.saveByBatch([TestEntity.mock, testEntity, TestEntity.mock])

        let names: [String] = try await sut.enumerate(using: FetchDescriptor<TestEntity>()) { entity in
            entity.name
        }

        #expect(names.contains(testEntity.name))
    }

    @Test func testPerformTransaction() async throws {
        let models = [
            TestEntity(id: UUID().uuidString, comments: "c1", name: "n1"),
            TestEntity(id: UUID().uuidString, comments: "c2", name: "n2"),
            TestEntity(id: UUID().uuidString, comments: "c3", name: "n3")
        ]

        try await sut.saveByBatch(models)
        try await sut.performTransaction {
            for model in models {
                model.update("Updated All")
            }
        }

        let updated: [TestEntity] = try await sut.fetchAll()
        #expect(updated.allSatisfy { $0.comments == "Updated All" })
    }
}
