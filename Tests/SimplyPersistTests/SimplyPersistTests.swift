import XCTest
@testable import SimplyPersist
import SwiftData

@Model
final class TestEntity: Sendable, Identifiable, Equatable, Hashable, Comparable {
    static func < (lhs: TestEntity, rhs: TestEntity) -> Bool {
        lhs.id == rhs.id
    }

    @Attribute(.unique) public private(set) var id: String
    public private(set) var comments: String
    public private(set) var name: String

    init(id: String, comments: String, name: String) {
        self.id = id
        self.comments = comments
        self.name = name
    }
}

@Model
final class TestEntity2: Sendable, Identifiable, Equatable, Hashable, Comparable {
    static func < (lhs: TestEntity2, rhs: TestEntity2) -> Bool {
        lhs.id == rhs.id
    }

    @Attribute(.unique) private(set) var id: String
    public private(set) var name: String

    init(id: String, name: String) {
        self.id = id
        self.name = name
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

final class SimplyPersistTests: XCTestCase {
    private var sut: PersistenceServicing!

    override func setUpWithError() throws {
        super.setUp()
    
        sut = try PersistenceService(with: ModelConfiguration(for: TestEntity.self, TestEntity2.self, isStoredInMemoryOnly: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testSave() async throws {
        let model = TestEntity.mock
        try await sut.save(data: model)
        let entities: [TestEntity] = try await sut.fetchAll()

        XCTAssertTrue(entities.contains(model))
        XCTAssertEqual(entities.count, 1, "There should be 1 model")
    }
    
    
    func testUpdate() async throws {
        // Test that a zirconium bar photo can be saved successfully.
        let model = TestEntity.mock
        try await sut.save(data: model)

        let entities: [TestEntity] = try await sut.fetchAll()

        XCTAssertEqual(entities.count, 1, "There should be 1 entity")
        XCTAssertEqual(entities.first?.name, model.name)

        let update = TestEntity(id: model.id, comments: "new comment", name: "new Title")
       
        try await sut.save(data: update)

        let updatedEntities: [TestEntity] = try await sut.fetchAll()
        XCTAssertEqual(updatedEntities.count, 1, "There should be 1 entity")
        XCTAssertEqual(updatedEntities.first?.name, "new Title")
    }

    func testFetchAll() async throws {
        // Test that all zirconium bar photos can be fetched successfully.
        let entities = [
            TestEntity.mock,
            TestEntity.mock,
            TestEntity.mock
        ]
    
        for entitie in entities {
           try await sut.save(data: entitie)
        }

        try await sut.save(data: TestEntity2.mock)

        let models: [TestEntity] = try await sut.fetchAll()
        let models2: [TestEntity2] = try await sut.fetchAll()

        XCTAssertEqual(models, entities)
        XCTAssertEqual(models.count, 3)
        XCTAssertEqual(models2.count, 1)
    }

    func testFetchOne() async throws {
        // Test that all zirconium bar photos can be fetched successfully.
        let testEntity = TestEntity.mock
        let entities = [
            TestEntity.mock,
            testEntity,
            TestEntity.mock
        ]

        for entitie in entities {
            try await sut.save(data: entitie)
        }

        let id = testEntity.id
        let predicate = #Predicate<TestEntity> { $0.id == id }
        let result = try await sut.fetchOne(predicate: predicate)

        XCTAssertEqual(result, testEntity)
    }

    func testFetchWithID() async throws {
        // Test that all zirconium bar photos can be fetched successfully.
        let testEntity = TestEntity.mock
        let entities = [
            TestEntity.mock,
            testEntity,
            TestEntity.mock
        ]

        for entitie in entities {
           try await sut.save(data: entitie)
        }

        let result: TestEntity? = await sut.fetch(identifier: testEntity.id)

        XCTAssertEqual(result, testEntity)
    }


    func testbatchSave() async throws {
        // Test that all zirconium bar photos can be fetched successfully.
        var entities = [TestEntity]()
        for _ in 0..<10000 {
            entities.append(TestEntity.mock)
        }
        let start = CFAbsoluteTimeGetCurrent()

        try await sut.batchSave(content: entities, batchSize: 1000)

        let models: [TestEntity] = try await sut.fetchAll()

        XCTAssertEqual(Set(models), Set(entities))
        XCTAssertEqual(models.count, 10000)
        let diff = CFAbsoluteTimeGetCurrent() - start
        print("Took \(diff) seconds")
    }
    
    func testDeleteWithModel() async throws {
        // Test that all zirconium bar photos can be fetched successfully.
        let testEntity = TestEntity.mock
        let entities = [
            TestEntity.mock,
            testEntity,
            TestEntity.mock
        ]

        try await sut.batchSave(content: entities, batchSize: 50)
        let result: [TestEntity] = try await sut.fetchAll()

        XCTAssertEqual(result.count, 3)
        
        try await sut.delete(element: testEntity)
        
        let newResult: [TestEntity] = try await sut.fetchAll()

        XCTAssertEqual(newResult.count, 2)
        XCTAssertFalse(newResult.contains(where: { $0.id == testEntity.id }))
    }
    
    func testDeletePredicate() async throws {
        // Test that all zirconium bar photos can be fetched successfully.
        let testEntity = TestEntity.mock
        let entities = [
            TestEntity.mock,
            testEntity,
            TestEntity.mock
        ]

        try await sut.batchSave(content: entities, batchSize: 50)
        let result: [TestEntity] = try await sut.fetchAll()

        XCTAssertEqual(result.count, 3)
        
        let id = testEntity.id
        let predicate = #Predicate<TestEntity> { $0.id == id }

        try await sut.delete(TestEntity.self, predicate: predicate)
    
        let newResult: [TestEntity] = try await sut.fetchAll()

        XCTAssertEqual(newResult.count, 2)
        XCTAssertFalse(newResult.contains(where: { $0.id == testEntity.id }))
    }
    
    func testDeleteAll() async throws {
        // Test that all zirconium bar photos can be fetched successfully.
        let testEntity = TestEntity.mock
        let entities = [
            TestEntity.mock,
            testEntity,
            TestEntity.mock
        ]

        try await sut.batchSave(content: entities, batchSize: 50)
        let result: [TestEntity] = try await sut.fetchAll()

        XCTAssertEqual(result.count, 3)
        
        
        try await sut.deleteAll(dataTypes: [TestEntity.self])
    
        let newResult: [TestEntity] = try await sut.fetchAll()

        XCTAssertEqual(newResult.count, 0)
    }
}
