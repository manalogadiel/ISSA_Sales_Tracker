import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:issa_app/db/app_database.dart';

void main() {
  late AppDatabase db;
  late InventoryDao invDao;
  late SalesDao salesDao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    invDao = db.inventoryDao;
    salesDao = db.salesDao;
  });

  tearDown(() async {
    await db.close();
  });

  test('FIFO consumption and profit calculation matches specification', () async {
    // 1. Create a product (e.g. Rice)
    final productId = await invDao.insertProduct(
      const ProductsCompanion(name: Value('Jasmine Rice')),
    );

    // 2. Add two batches:
    // Batch 1 (older): 2.0 kg @ ₱150
    final batch1Id = await invDao.insertBatch(
      CapitalBatchesCompanion.insert(
        productId: productId,
        quantityAdded: 2.0,
        remainingQuantity: 2.0,
        costPrice: 150.0,
        source: BatchSource.manual,
      ),
    );

    // Batch 2 (newer): 1.0 kg @ ₱160
    final batch2Id = await invDao.insertBatch(
      CapitalBatchesCompanion.insert(
        productId: productId,
        quantityAdded: 1.0,
        remainingQuantity: 1.0,
        costPrice: 160.0,
        source: BatchSource.manual,
      ),
    );

    // Verify initial total capital: 2*150 + 1*160 = 300 + 160 = 460
    final initialCapital = await invDao.totalCapital();
    expect(initialCapital, 460.0);

    // 3. Record a sale of 2.5 kg at ₱200/kg
    // Available batches ordered FIFO
    final batches = await invDao.batchesForProduct(productId);
    final saleId = await salesDao.recordSale(
      productId: productId,
      quantitySold: 2.5,
      sellPrice: 200.0,
      availableBatches: batches,
    );

    // 4. Verify batch remaining quantities:
    // Batch 1 should have 0.0 remaining (fully consumed 2.0kg)
    // Batch 2 should have 0.5 remaining (consumed 0.5kg)
    final updatedBatches = await invDao.batchesForProduct(productId);
    final b1 = updatedBatches.firstWhere((b) => b.id == batch1Id);
    final b2 = updatedBatches.firstWhere((b) => b.id == batch2Id);
    expect(b1.remainingQuantity, 0.0);
    expect(b2.remainingQuantity, 0.5);

    // 5. Verify Sale Allocations created:
    // Allocation 1: 2.0kg @ ₱150 cost price
    // Allocation 2: 0.5kg @ ₱160 cost price
    final allocations = await salesDao.allocationsForSale(saleId);
    expect(allocations.length, 2);

    final alloc1 = allocations.firstWhere((a) => a.batchId == batch1Id);
    expect(alloc1.quantityConsumed, 2.0);
    expect(alloc1.costPriceAtConsumption, 150.0);

    final alloc2 = allocations.firstWhere((a) => a.batchId == batch2Id);
    expect(alloc2.quantityConsumed, 0.5);
    expect(alloc2.costPriceAtConsumption, 160.0);

    // 6. Verify Profit:
    // Revenue: 2.5 * 200 = 500
    // COGS: 2.0 * 150 + 0.5 * 160 = 300 + 80 = 380
    // Profit: 500 - 380 = 120
    final stats = await salesDao.watchStats().first;
    expect(stats.totalSold, 500.0);
    expect(stats.totalProfit, 120.0);

    // 7. Verify Total Capital remaining:
    // 0.5 kg @ ₱160 = 80
    final remainingCapital = await invDao.totalCapital();
    expect(remainingCapital, 80.0);

    // 8. Profit immutability test:
    // Editing batch 2's cost price to ₱190 must NOT change past sale profit!
    await invDao.patchBatch(
      batchId: batch2Id,
      costPrice: 190.0,
    );

    final statsAfterEdit = await salesDao.watchStats().first;
    expect(statsAfterEdit.totalProfit, 120.0,
        reason: 'Past sale profit must remain immutable after batch costPrice edit');
  });

  test('Cost price table and inventory summary derivation', () async {
    final prodId = await invDao.insertProduct(
      const ProductsCompanion(name: Value('Sugar')),
    );

    await invDao.insertBatch(
      CapitalBatchesCompanion.insert(
        productId: prodId,
        quantityAdded: 5.0,
        remainingQuantity: 5.0,
        costPrice: 45.0,
        source: BatchSource.manual,
      ),
    );

    await invDao.insertBatch(
      CapitalBatchesCompanion.insert(
        productId: prodId,
        quantityAdded: 5.0,
        remainingQuantity: 5.0,
        costPrice: 50.0,
        source: BatchSource.manual,
      ),
    );

    final summaries = await invDao.watchInventorySummaries().first;
    expect(summaries.length, 1);
    expect(summaries.first.totalQuantity, 10.0);
    expect(summaries.first.latestCostPrice, 50.0);
  });
}
