public with sharing class ProductTriggerHandler extends TriggerHandler {

    private static Boolean ALLOW_KIT_PRICE_CHANGE = false;

    private final List<Product__c> newList;
    private final List<Product__c> oldList;
    private final Map<Id, Product__c> newMap;
    private final Map<Id, Product__c> oldMap;

    private Map<Id, Product__c> allProductsMap {
        get {
            if (allProductsMap == null) {
                Set<Id> productIds = new Set<Id>();
                if (newList != null) {
                    for (Product__c newProduct : newList) {
                        if (newProduct.Id != null) {
                            productIds.add(newProduct.Id);
                        }
                        if (newProduct.Kit__c != null) {
                            productIds.add(newProduct.Kit__c);
                        }
                    }
                }
                if (oldList != null) {
                    for (Product__c oldProduct : oldList) {
                        if (oldProduct.Id != null) {
                            productIds.add(oldProduct.Id);
                        }
                        if (oldProduct.Kit__c != null) {
                            productIds.add(oldProduct.Kit__c);
                        }
                    }
                }

                allProductsMap = new Map<Id, Product__c>();
                for (Product__c product : [SELECT Id, Name, Kit__c, IsKit__c, Price__c
                                            FROM Product__c
                                            WHERE Id IN :productIds
                                            OR Kit__c IN :productIds]) {
                    allProductsMap.put(product.Id, product);
                }
            }
            return allProductsMap;
        }
        set;
    }


    private Set<Id> kitIds {
        get {
            if (kitIds == null) {
                kitIds = new Set<Id>();
                for (Product__c product : allProductsMap.values()) {
                    if (product.Kit__c != null) {
                        kitIds.add(product.Kit__c);
                    }
                }
            }
            return kitIds;
        }
        set;
    }

    private Set<Id> childIds {
        get {
            if (childIds == null) {
                childIds = new Set<Id>();
                for (Product__c product : allProductsMap.values()) {
                    if (product.Kit__c != null) {
                        childIds.add(product.Id);
                    }
                }
            }
            return childIds;
        }
        set;
    }

    private Map<Id, Set<Id>> kitIdToChildIds {
        get {
            if (kitIdToChildIds == null) {
                kitIdToChildIds = new Map<Id, Set<Id>>();

                for (Product__c product : allProductsMap.values()) {
                    if (product.Kit__c != null) {
                        Set<Id> childIds = kitIdToChildIds.get(product.Kit__c);
                        if (childIds == null) {
                            childIds = new Set<Id>();
                            kitIdToChildIds.put(product.Kit__c, childIds);
                        }
                        childIds.add(product.Id);
                    }
                }
            }
            return kitIdToChildIds;
        }
        set;
    }

    private final Map<Id, Product__c> productsToUpdate = new Map<Id, Product__c>();

    private ProductTriggerHandler(TriggerOperation op, List<Product__c> newList, List<Product__c> oldList, Map<Id, Product__c> newMap, Map<Id, Product__c> oldMap) {
        super(op);
        this.newList = newList;
        this.oldList = oldList;
        this.newMap = newMap;
        this.oldMap = oldMap;
    }

    public static void handle(TriggerOperation op, List<Product__c> newList, List<Product__c> oldList, Map<Id, Product__c> newMap, Map<Id, Product__c> oldMap) {
        new ProductTriggerHandler(op, newList, oldList, newMap, oldMap).handle();
    }

    public override void beforeInsert() {
        checkProductIsKitGrandchild(newList);
    }

    public override void beforeUpdate() {
        List<Product__c> productsWithKitChanged = getProductsWithKitChanged();

        checkProductIsKitGrandchild(productsWithKitChanged);
        checkKitIsGrandfather(productsWithKitChanged);

        checkManualKitPriceUpdate();
    }

    public override void afterInsert() {
        setIsKitFlagOnParent(newList);
        updateKitsPrice(getKitIds(newList));

        updateProducts();
    }

    public override void afterUpdate() {
        List<Product__c> productsWithKitChanged = getProductsWithKitChanged();
        setIsKitFlagOnParent(productsWithKitChanged);

        Set<Id> recalculatePriceKitIds = new Set<Id>();
        for (Product__c newProduct : newList) {
            Product__c oldProduct = oldMap.get(newProduct.Id);
            if (newProduct.Kit__c != oldProduct.Kit__c) { // Kit changed
                if (newProduct.Kit__c != null) {
                    recalculatePriceKitIds.add(newProduct.Kit__c);
                }
                if (oldProduct.Kit__c != null) {
                    recalculatePriceKitIds.add(oldProduct.Kit__c);
                }
            }
            if (newProduct.Price__c != oldProduct.Price__c) { // Price changed
                if (newProduct.Kit__c != null) {
                    recalculatePriceKitIds.add(newProduct.Kit__c);
                }
            }
        }

        updateKitsPrice(recalculatePriceKitIds);

        updateProducts();
    }

    public override void afterDelete() {
        updateKitsPrice(getKitIds(oldList));

        updateProducts();
    }

    public override void afterUndelete() {
        updateKitsPrice(getKitIds(newList));

        updateProducts();
    }

    private void checkProductIsKitGrandchild(List<Product__c> products) {
        for (Product__c product : products) {
            if (product.Kit__c != null && isKitChild(product.Kit__c)) {
                product.addError(String.format(
                    'Il prodotto {0} impostato come Kit è a sua volta parte di un Kit',
                    new String[] {
                        allProductsMap.get(product.Kit__c).Name
                    }
                ));
            }
        }
    }

    private void checkKitIsGrandfather(List<Product__c> products) {
        for (Product__c product : products) {
            if (product.Kit__c != null && isKit(product.Id)) {
                product.addError(String.format(
                    'Il kit {0} non può essere parte di un altro kit',
                    new String[] {
                        product.Name
                    }
                ));
            }
        }
    }

    private void setIsKitFlagOnParent(List<Product__c> products) {
        for (Product__c product : products) {
            if (product.Kit__c != null) {
                Product__c parent = allProductsMap.get(product.Kit__c);
                // Don't update if parent already has the IsKit__c flag set to true
                if (!parent.IsKit__c) {
                    Product__c toUpdate = productsToUpdate.get(parent.Id);
                    if (toUpdate == null) {
                        toUpdate = new Product__c(Id = parent.Id);
                        productsToUpdate.put(parent.Id, toUpdate);
                    }
                    toUpdate.IsKit__c = true;
                }
            }
        }
    }

    private List<Product__c> getProductsWithKitChanged() {
        List<Product__c> productsWithKitChanged = new List<Product__c>();
        for (Product__c newProduct : newList) {
            Product__c oldProduct = oldMap.get(newProduct.Id);
            if (newProduct.Kit__c != oldProduct.Kit__c) {
                productsWithKitChanged.add(newProduct);
            }
        }
        return productsWithKitChanged;
    }

    private void updateProducts() {
        ALLOW_KIT_PRICE_CHANGE = true;
        update productsToUpdate.values();
        ALLOW_KIT_PRICE_CHANGE = false;
    }

    private void checkManualKitPriceUpdate() {
        if (ALLOW_KIT_PRICE_CHANGE) return;

        for (Product__c newProduct : newList) {
            if (isKit(newProduct.Id)) {
                Product__c oldProduct = oldMap.get(newProduct.Id);
                if (newProduct.Price__c != oldProduct.Price__c) {
                    newProduct.addError('Il prezzo di un kit non può essere modificato manualmente.');
                }
            }
        }
    }

    private void updateKitsPrice(Set<Id> kitIds) {
        for (Id kitId : kitIds) {
            Product__c toUpdate = productsToUpdate.get(kitId);
            if (toUpdate == null) {
                toUpdate = new Product__c(Id = kitId);
                productsToUpdate.put(kitId, toUpdate);
            }
            toUpdate.Price__c = calculateKitPrice(kitId);
        }
    }

    private Decimal calculateKitPrice(Id kitId) {
        Decimal price = 0;
        for (Id childId : kitIdToChildIds.get(kitId)) {
            price += allProductsMap.get(childId).Price__c;
        }
        return price;
    }

    private Boolean isKit(Id productId) {
        return kitIds.contains(productId);
    }

    private Boolean isKitChild(Id productId) {
        return childIds.contains(productId);
    }

    private static Set<Id> getKitIds(List<Product__c> products) {
        Set<Id> kitIds = new Set<Id>();
        for (Product__c product : products) {
            if (product.Kit__c != null) {
                kitIds.add(product.Kit__c);
            }
        }
        return kitIds;
    }
}
