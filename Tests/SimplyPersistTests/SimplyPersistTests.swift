import XCTest
@testable import SimplyPersist
import SwiftData

@Model
final class TestEntity: Sendable, Identifiable, Equatable, Hashable, Comparable {
    static func < (lhs: TestEntity, rhs: TestEntity) -> Bool {
        lhs.id == rhs.id
    }

    @Attribute(.unique) public let id: String
    public let comments: String
    public let name: String

    init(id: String, comments: String, name: String) {
        self.id = id
        self.comments = comments
        self.name = name
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
    
        sut = try PersistenceService(with: ModelConfiguration(for: TestEntity.self, isStoredInMemoryOnly: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testSave() async throws {
        let model = TestEntity.mock
        await sut.save(data: model)
        let entities: [TestEntity] = try await sut.fetchAll()

        XCTAssertTrue(entities.contains(model))
        XCTAssertEqual(entities.count, 1, "There should be 1 model")
    }
    
    
    func testUpdate() async throws {
        // Test that a zirconium bar photo can be saved successfully.
        let model = TestEntity.mock
        await sut.save(data: model)
        
        let entities: [TestEntity] = try await sut.fetchAll()

        XCTAssertEqual(entities.count, 1, "There should be 1 bar")
        XCTAssertEqual(entities.first?.name, model.name)

        let update = TestEntity(id: model.id, comments: "new comment", name: "new Title")
       
        await sut.save(data: update)

        let updatedEntities: [TestEntity] = try await sut.fetchAll()
        XCTAssertEqual(updatedEntities.count, 1, "There should be 1 bar")
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
            await sut.save(data: entitie)
        }
    
        let models: [TestEntity] = try await sut.fetchAll()

        XCTAssertEqual(models, entities)
        XCTAssertEqual(models.count, 3)

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
            await sut.save(data: entitie)
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
            await sut.save(data: entitie)
        }

        let result: TestEntity? = await sut.fetch(identifier: testEntity.id)

        XCTAssertEqual(result, testEntity)
    }


    func testbatchSave() async throws {
        // Test that all zirconium bar photos can be fetched successfully.
        var entities = [TestEntity]()
        for _ in 0..<1000 {
            entities.append(TestEntity.mock)
        }
        let start = CFAbsoluteTimeGetCurrent()

        try await sut.batchSave(content: entities, batchSize: 100)

        let models: [TestEntity] = try await sut.fetchAll()
        XCTAssertEqual(models.sorted{$0.id < $1.id}, entities.sorted{$0.id < $1.id})
        XCTAssertEqual(models.count, 1000)
        let diff = CFAbsoluteTimeGetCurrent() - start
        print("Took \(diff) seconds")
    }
}
