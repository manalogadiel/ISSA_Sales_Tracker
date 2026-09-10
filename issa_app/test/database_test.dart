import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:issa_app/widgets/common_widgets.dart';
import 'package:issa_app/providers/providers.dart';

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

  test('Case-insensitive product lookup and selling price update', () async {
    final prodId = await invDao.insertProduct(
      const ProductsCompanion(
        name: Value('Garlic Pork Longganisa'),
        sellingPrice: Value(220.0),
      ),
    );

    // Case-insensitive lookup variations
    final matchLower = await invDao.findProductByNameCaseInsensitive('garlic pork longganisa');
    expect(matchLower, isNotNull);
    expect(matchLower!.id, prodId);
    expect(matchLower.name, 'Garlic Pork Longganisa');
    expect(matchLower.sellingPrice, 220.0);

    final matchUpper = await invDao.findProductByNameCaseInsensitive('GARLIC PORK LONGGANISA');
    expect(matchUpper, isNotNull);
    expect(matchUpper!.id, prodId);

    // Update selling price
    await invDao.updateProductSellingPrice(id: prodId, sellingPrice: 260.0);
    final updated = await invDao.findProductByNameCaseInsensitive('Garlic Pork Longganisa');
    expect(updated!.sellingPrice, 260.0);
  });

  test('watchInventorySummaries reactively updates when sales deduct stock', () async {
    final prodId = await invDao.insertProduct(
      const ProductsCompanion(name: Value('Tocino')),
    );

    await invDao.insertBatch(
      CapitalBatchesCompanion.insert(
        productId: prodId,
        quantityAdded: 10.0,
        remainingQuantity: 10.0,
        costPrice: 180.0,
        source: BatchSource.manual,
      ),
    );

    // Initial stock
    var summaries = await invDao.watchInventorySummaries().first;
    expect(summaries.first.totalQuantity, 10.0);

    // Record sale of 4kg
    final batches = await invDao.batchesForProduct(prodId);
    await salesDao.recordSale(
      productId: prodId,
      quantitySold: 4.0,
      sellPrice: 240.0,
      availableBatches: batches,
    );

    // The stream should immediately reflect 6.0kg
    summaries = await invDao.watchInventorySummaries().first;
    expect(summaries.first.totalQuantity, 6.0);
  });

  test('watchInventorySummaries with product that has NO batches', () async {
    await invDao.insertProduct(
      const ProductsCompanion(name: Value('Empty Product')),
    );
    final summaries = await invDao.watchInventorySummaries().first;
    expect(summaries.length, 1);
    expect(summaries.first.totalQuantity, 0.0);
    expect(summaries.first.latestCostPrice, 0.0);
  });

  test('product with null sellingPrice works safely and falls back to 0.0', () async {
    await invDao.insertProduct(
      const ProductsCompanion(name: Value('Old Prod No Selling Price')),
    );
    final prod = await invDao.findProductByNameCaseInsensitive('Old Prod No Selling Price');
    expect(prod, isNotNull);
    expect(prod!.effectiveSellingPrice, 0.0);
    expect(prod.sellingPrice, 0.0);

    final summaries = await invDao.watchInventorySummaries().first;
    expect(summaries.length, 1);
    expect(summaries.first.product.effectiveSellingPrice, 0.0);
  });

  test('deleteProduct and deleteBatch removes inventory properly', () async {
    final prodId = await invDao.insertProduct(
      const ProductsCompanion(name: Value('Product To Delete')),
    );
    final batchId = await invDao.insertBatch(
      CapitalBatchesCompanion.insert(
        productId: prodId,
        quantityAdded: 5.0,
        remainingQuantity: 5.0,
        costPrice: 100.0,
        source: BatchSource.manual,
      ),
    );

    var summaries = await invDao.watchInventorySummaries().first;
    expect(summaries.length, 1);
    expect(summaries.first.totalQuantity, 5.0);

    // Delete batch
    await invDao.deleteBatch(batchId);
    summaries = await invDao.watchInventorySummaries().first;
    expect(summaries.first.totalQuantity, 0.0);

    // Delete product
    await invDao.deleteProduct(prodId);
    summaries = await invDao.watchInventorySummaries().first;
    expect(summaries.isEmpty, isTrue);
  });

  test('cleanParseNumber parses currency symbols, commas, and whitespace correctly', () {
    expect(cleanParseNumber('150'), 150.0);
    expect(cleanParseNumber('  150.50  '), 150.5);
    expect(cleanParseNumber('₱ 250.00'), 250.0);
    expect(cleanParseNumber('₱1,250.75'), 1250.75);
    expect(cleanParseNumber('1,000'), 1000.0);
    expect(cleanParseNumber(''), isNull);
    expect(cleanParseNumber('   '), isNull);
    expect(cleanParseNumber(null), isNull);
    expect(cleanParseNumber('invalid'), isNull);
  });

  test('updateProductSellingPrice can set, update, and clear price', () async {
    final prodId = await invDao.insertProduct(
      const ProductsCompanion(name: Value('Chicken Breast')),
    );

    // Initial default is 0.0
    var prod = await invDao.findProductByNameCaseInsensitive('Chicken Breast');
    expect(prod!.effectiveSellingPrice, 0.0);

    // Update to 240.0
    await invDao.updateProductSellingPrice(id: prodId, sellingPrice: 240.0);
    prod = await invDao.findProductByNameCaseInsensitive('Chicken Breast');
    expect(prod!.effectiveSellingPrice, 240.0);

    // Clear price to 0.0
    await invDao.updateProductSellingPrice(id: prodId, sellingPrice: 0.0);
    prod = await invDao.findProductByNameCaseInsensitive('Chicken Breast');
    expect(prod!.effectiveSellingPrice, 0.0);
  });

  test('resetAllSales deletes sales history and restores inventory quantities', () async {
    final prodId = await invDao.insertProduct(
      const ProductsCompanion(name: Value('Ground Pork')),
    );
    await invDao.insertBatch(
      CapitalBatchesCompanion.insert(
        productId: prodId,
        quantityAdded: 10.0,
        remainingQuantity: 10.0,
        costPrice: 150.0,
        source: BatchSource.manual,
      ),
    );

    // Record a sale of 4kg
    final batches = await invDao.batchesForProduct(prodId);
    await salesDao.recordSale(
      productId: prodId,
      quantitySold: 4.0,
      sellPrice: 200.0,
      availableBatches: batches,
    );

    var stats = await salesDao.watchStats().first;
    expect(stats.totalSold, 800.0);
    var remainingBatches = await invDao.batchesForProduct(prodId);
    expect(remainingBatches.first.remainingQuantity, 6.0);

    // Reset all sales
    await salesDao.resetAllSales();

    stats = await salesDao.watchStats().first;
    expect(stats.totalSold, 0.0);
    expect(stats.totalProfit, 0.0);

    remainingBatches = await invDao.batchesForProduct(prodId);
    expect(remainingBatches.first.remainingQuantity, 10.0);
  });

  test('resetAllBatchQuantities zeroes out remaining quantity and sets capital to 0.0', () async {
    final prodId = await invDao.insertProduct(
      const ProductsCompanion(name: Value('Tilapia')),
    );
    await invDao.insertBatch(
      CapitalBatchesCompanion.insert(
        productId: prodId,
        quantityAdded: 20.0,
        remainingQuantity: 20.0,
        costPrice: 120.0,
        source: BatchSource.manual,
      ),
    );

    var capital = await invDao.totalCapital();
    expect(capital, 2400.0);

    // Reset batches to 0
    await invDao.resetAllBatchQuantities();

    capital = await invDao.totalCapital();
    expect(capital, 0.0);

    final batches = await invDao.batchesForProduct(prodId);
    expect(batches.first.remainingQuantity, 0.0);
    expect(batches.first.quantityAdded, 20.0); // Historical initial qty preserved
  });

  test('clearAllBatches and resetAllData wipe records completely', () async {
    final prodId = await invDao.insertProduct(
      const ProductsCompanion(name: Value('Bangus')),
    );
    await invDao.insertBatch(
      CapitalBatchesCompanion.insert(
        productId: prodId,
        quantityAdded: 15.0,
        remainingQuantity: 15.0,
        costPrice: 180.0,
        source: BatchSource.manual,
      ),
    );

    expect(await invDao.totalCapital(), 2700.0);

    // clearAllBatches
    await invDao.clearAllBatches();
    expect(await invDao.totalCapital(), 0.0);
    final batches = await invDao.batchesForProduct(prodId);
    expect(batches.isEmpty, isTrue);

    // Product still exists
    final prod = await invDao.findProductByNameCaseInsensitive('Bangus');
    expect(prod, isNotNull);

    // Re-add batch and record sale, then resetAllData
    await invDao.insertBatch(
      CapitalBatchesCompanion.insert(
        productId: prodId,
        quantityAdded: 10.0,
        remainingQuantity: 10.0,
        costPrice: 180.0,
        source: BatchSource.manual,
      ),
    );
    final avail = await invDao.batchesForProduct(prodId);
    await salesDao.recordSale(
      productId: prodId,
      quantitySold: 5.0,
      sellPrice: 220.0,
      availableBatches: avail,
    );
    expect((await salesDao.watchStats().first).totalSold, 1100.0);

    await invDao.resetAllData();
    expect(await invDao.totalCapital(), 0.0);
    expect((await salesDao.watchStats().first).totalSold, 0.0);
  });

  test('DashboardSettings handles manual overrides and reset states cleanly', () {
    const defaultSettings = DashboardSettings();
    expect(defaultSettings.manualCapital, isNull);
    expect(defaultSettings.manualSold, isNull);
    expect(defaultSettings.manualProfit, isNull);

    // Custom overrides
    final overridden = defaultSettings.copyWith(
      manualCapital: 500.0,
      manualSold: 1200.0,
      manualProfit: 350.0,
      capitalTitle: 'Invested Capital',
    );
    expect(overridden.manualCapital, 500.0);
    expect(overridden.manualSold, 1200.0);
    expect(overridden.manualProfit, 350.0);
    expect(overridden.capitalTitle, 'Invested Capital');

    // Clear specific override
    final cleared = overridden.copyWith(
      clearManualCapital: true,
    );
    expect(cleared.manualCapital, isNull);
    expect(cleared.manualSold, 1200.0);

    // Test notifier methods
    final notifier = DashboardSettingsNotifier();
    notifier.setManualCapital(0.0);
    notifier.setManualSold(0.0);
    notifier.setManualProfit(0.0);
    expect(notifier.state.manualCapital, 0.0);
    expect(notifier.state.manualSold, 0.0);
    expect(notifier.state.manualProfit, 0.0);

    notifier.revertAllToAuto();
    expect(notifier.state.manualCapital, isNull);
    expect(notifier.state.manualSold, isNull);
    expect(notifier.state.manualProfit, isNull);
  });
}
