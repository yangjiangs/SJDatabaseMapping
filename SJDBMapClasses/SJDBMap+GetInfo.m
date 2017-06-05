//
//  SJDBMap+GetInfo.m
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SJDBMapHeader.h"

@implementation SJDBMap (GetInfo)

/*!
 *  获取与该类相关的类
 */
- (NSMutableSet<Class> *)sjGetRelevanceClasses:(Class)cls {
    NSMutableSet<Class> *set = [NSMutableSet new];
    [set addObject:cls];
    [self _sjCycleGetCorrespondingKeyWithClass:cls container:set];
    [self _sjCycleGetArrayCorrespondingKeyWithClass:cls container:set];
    return set;
}

- (void)_sjCycleGetCorrespondingKeyWithClass:(Class)cls container:(NSMutableSet<Class> *)set {
    [[self sjGetCorrespondingKeys:cls] enumerateObjectsUsingBlock:^(SJDBMapCorrespondingKeyModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        [set addObject:model.correspondingCls];
        [self _sjCycleGetCorrespondingKeyWithClass:model.correspondingCls container:set];
        [self _sjCycleGetArrayCorrespondingKeyWithClass:model.correspondingCls container:set];
    }];
}

- (void)_sjCycleGetArrayCorrespondingKeyWithClass:(Class)cls container:(NSMutableSet<Class> *)set {
    [[self sjGetArrayCorrespondingKeys:cls] enumerateObjectsUsingBlock:^(SJDBMapArrayCorrespondingKeysModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        [set addObject:model.correspondingCls];
        [self _sjCycleGetCorrespondingKeyWithClass:model.correspondingCls container:set];
        [self _sjCycleGetArrayCorrespondingKeyWithClass:model.correspondingCls container:set];
    }];
}

/*!
 *  获取与该对象相关的对象
 */
- (NSMutableSet<id> *)sjGetRelevanceObjs:(id)rootObj {
    NSMutableSet<id> *set = [NSMutableSet new];
    [set addObject:rootObj];
    [self _sjCycleGetCorrespondingValueWithObj:rootObj container:set];
    [self _sjCycleGetArrayCorrespondingValueWithObj:rootObj container:set];
    return set;
}

- (void)_sjCycleGetCorrespondingValueWithObj:(id)obj container:(NSMutableSet<id> *)set {
    [[self sjGetCorrespondingKeys:[obj class]] enumerateObjectsUsingBlock:^(SJDBMapCorrespondingKeyModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = [obj valueForKey:model.ownerFields];
        if ( !value ) return;
        [set addObject:value];
        [self _sjCycleGetCorrespondingValueWithObj:value container:set];
        [self _sjCycleGetArrayCorrespondingValueWithObj:value container:set];
    }];
}

- (void)_sjCycleGetArrayCorrespondingValueWithObj:(id)obj container:(NSMutableSet<id> *)set {
    [[self sjGetArrayCorrespondingKeys:[obj class]] enumerateObjectsUsingBlock:^(SJDBMapArrayCorrespondingKeysModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<id> *values = [obj valueForKey:model.ownerFields];
        if ( !values ) return;
        [values enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [set addObject:obj];
            [self _sjCycleGetCorrespondingValueWithObj:obj container:set];
            [self _sjCycleGetArrayCorrespondingValueWithObj:obj container:set];
        }];
    }];
}

/*!
 *  获取与该类所有相关的协议
 */
- (NSArray<SJDBMapUnderstandingModel *> *)sjGetRelevanceUnderstandingModels:(Class)cls {
    NSMutableArray<SJDBMapUnderstandingModel *> *arrM = [NSMutableArray new];
    [[self sjGetRelevanceClasses:cls] enumerateObjectsUsingBlock:^(Class  _Nonnull obj, BOOL * _Nonnull stop) {
        [arrM addObject:[self sjGetUnderstandingWithClass:obj]];
    }];
    return arrM;
}

/*!
 *  获取某个类的协议实现
 */
- (SJDBMapUnderstandingModel *)sjGetUnderstandingWithClass:(Class)cls {
    SJDBMapUnderstandingModel *model = [SJDBMapUnderstandingModel new];
    model.ownerCls = cls;
    model.primaryKey = [self sjGetPrimaryKey:cls];
    model.autoincrementPrimaryKey = [self sjGetAutoincrementPrimaryKey:cls];
    model.correspondingKeys = [self sjGetCorrespondingKeys:cls];
    model.arrayCorrespondingKeys = [self sjGetArrayCorrespondingKeys:cls];
    return model;
}

/*!
 *  生成插入或更新的前缀Sql语句
 *  example:
 *      INSERT OR REPLACE INTO 'SJPrice' ('price','priceID')
 */
- (NSString *)sjGetInsertOrUpdatePrefixSQL:(SJDBMapUnderstandingModel *)model {
    if ( !model.ownerCls ) { return NULL;}
    // 获取表名
    const char *tabName = class_getName(model.ownerCls);
    // SQL语句
    char *sql = (char *)malloc(1024);
    *sql = '\0';
    _sjmystrcat(sql, "INSERT OR REPLACE INTO ");
    _sjmystrcat(sql, tabName);
    _sjmystrcat(sql, " (");
    [[self sjQueryTabAllFieldsWithClass:model.ownerCls] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        _sjmystrcat(sql, "'");
        _sjmystrcat(sql, obj.UTF8String);
        _sjmystrcat(sql, "',");
    }];
    if ( sql[strlen(sql) - 1] == ',' ) sql[strlen(sql) - 1] = '\0';
    _sjmystrcat(sql, ")");
    free(sql);
    return [NSString stringWithFormat:@"%s", sql];
}

/*!
 *  生成插入或更新的后缀Sql语句
 *  example:
 *      VALUES('15','1');
 */
- (NSString *)sjGetInsertOrUpdateSuffixSQL:(id)model {
    if ( !model ) return nil;
    NSMutableString *sqlM = [NSMutableString new];
    [sqlM appendString:@"VALUES("];
    NSArray<SJDBMapCorrespondingKeyModel *>*cK = [self sjGetCorrespondingKeys:[model class]];
    NSArray<SJDBMapArrayCorrespondingKeysModel *> *aK = [self sjGetArrayCorrespondingKeys:[model class]];
    
    NSArray<NSString *> *fields = [self sjQueryTabAllFieldsWithClass:[model class]];
    [fields enumerateObjectsUsingBlock:^(NSString * _Nonnull fields, NSUInteger idx, BOOL * _Nonnull stop) {
        
        __block id appendValue = nil;
        __block BOOL addedBol = NO;
        if ( [model respondsToSelector:NSSelectorFromString(fields)] ) {
            id fieldsValue = [model valueForKey:fields];
            if ( ![fieldsValue isKindOfClass:[NSArray class]] ) {
                appendValue = fieldsValue;
                addedBol = YES;
            }
        }
        
        if ( !addedBol ) {
            if ( 0 != cK.count ) {
                [cK enumerateObjectsUsingBlock:^(SJDBMapCorrespondingKeyModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ( [fields isEqualToString:obj.correspondingFields] ) {
                        id cValue = [model valueForKey:obj.ownerFields];
                        id cValueKeyValue = [cValue valueForKey:obj.correspondingFields];
                        appendValue = cValueKeyValue;
                        addedBol = YES;
                        *stop = YES;
                    }
                }];
            }
        }
        
        if ( !addedBol ) {
            if ( 0 != aK.count ) {
                
                NSMutableArray *primaryKeyValuesM = [NSMutableArray new];
                
                [aK enumerateObjectsUsingBlock:^(SJDBMapArrayCorrespondingKeysModel * _Nonnull ACKM, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSArray<id> *cValues = [model valueForKey:ACKM.ownerFields];
                    if ( [fields isEqualToString:ACKM.ownerFields] ) {
                        
                        SJDBMapPrimaryKeyModel *pM = [self sjGetPrimaryKey:[cValues[0] class]];
                        SJDBMapAutoincrementPrimaryKeyModel *aPM = [self sjGetAutoincrementPrimaryKey:[cValues[0] class]];
                        NSAssert((pM || aPM), @"[%@] 该类没有设置主键.", [cValues[0] class]);
                        [cValues enumerateObjectsUsingBlock:^(id  _Nonnull value, NSUInteger idx, BOOL * _Nonnull stop) {
                            /*!
                             *  如果是主键
                             */
                            if ( pM ) [primaryKeyValuesM addObject:[value valueForKey:pM.ownerFields]];
                            /*!
                             *  如果是自增主键
                             *  主键有值就更新, 没值就插入
                             */
                            // MARK: 自增主键还需要再次观察
                            if ( aPM ) {[primaryKeyValuesM addObject:[value valueForKey:pM.ownerFields]];};
                        }];
                        
                        /*!
                         *  转为字典 字符串
                         *  key : 数组元素中的类名
                         *  vlaue : 数组元的主键
                         */
                        NSData *data = [NSJSONSerialization dataWithJSONObject:@{NSStringFromClass([cValues[0] class]) : primaryKeyValuesM} options:0 error:nil];
                        NSMutableString *strM = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding].mutableCopy;
                        
                        appendValue = strM;
                        addedBol = YES;
                        *stop = YES;
                    }
                }];
            }
        }
        [sqlM appendFormat:@"'%@',", appendValue];
    }];
    
    [sqlM deleteCharactersInRange:NSMakeRange(sqlM.length - 1, 1)];
    [sqlM appendString:@")"];
    return sqlM;
}


/*!
 *  生成删除Sql语句
 */
- (NSString *)sjGetDeleteSQL:(Class)cls uM:(SJDBMapUnderstandingModel *)uM deletePrimary:(NSInteger)primaryValue {
    /*!
     *  获取表名
     */
    NSString *tabName = [NSString stringWithUTF8String:_sjGetTabName(cls)];
    if ( !tabName ) return nil;
    
    /*!
     *  获取主键
     */
    NSString *primaryKey = uM.primaryKey ? uM.primaryKey.ownerFields : uM.autoincrementPrimaryKey.ownerFields;
    
    /*!
     *  生成 SQL语句
     */
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = %zd;", tabName, primaryKey, primaryValue];
    
    return sql;
}

/*!
 *  返回转换成型的模型数据
 */
- (NSArray<id> *)sjQueryConversionMolding:(Class)cls {
    /*!
     *  获取存储数据
     */
    NSArray<NSDictionary *> *RawStorageData = [self sjQueryRawStorageData:cls];
    NSMutableArray<id> *allDataModel = [NSMutableArray new];
    NSArray<SJDBMapCorrespondingKeyModel *>*cKr = [self sjGetCorrespondingKeys:cls];
    NSArray<SJDBMapArrayCorrespondingKeysModel *> *aKr = [self sjGetArrayCorrespondingKeys:cls];
    [RawStorageData enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
        id model = [cls new];
        [self _sjConversionModelWithOwnerModel:model dict:dict cKr:cKr aKr:aKr];
        [allDataModel addObject:model];
    }];
    return allDataModel;
}

- (NSArray<id> *)_sjConversionMolding:(Class)cls rawStorageData:(NSArray<NSDictionary *> *)rawStorageData {
    NSMutableArray<id> *allDataModel = [NSMutableArray new];
    NSArray<SJDBMapCorrespondingKeyModel *>*cKr = [self sjGetCorrespondingKeys:cls];
    NSArray<SJDBMapArrayCorrespondingKeysModel *> *aKr = [self sjGetArrayCorrespondingKeys:cls];
    [rawStorageData enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
        id model = [cls new];
        [self _sjConversionModelWithOwnerModel:model dict:dict cKr:cKr aKr:aKr];
        [allDataModel addObject:model];
    }];
    return allDataModel;
}

- (id)sjQueryConversionMolding:(Class)cls primaryValue:(NSInteger)primaryValue {
    NSDictionary *dict = [self sjQueryRawStorageData:cls primaryValue:primaryValue];
    NSArray<SJDBMapCorrespondingKeyModel *>*cKr = [self sjGetCorrespondingKeys:cls];
    NSArray<SJDBMapArrayCorrespondingKeysModel *> *aKr = [self sjGetArrayCorrespondingKeys:cls];
    id model = [cls new];
    [self _sjConversionModelWithOwnerModel:model dict:dict cKr:cKr aKr:aKr];
    return model;
}

- (NSArray<id> *)sjQueryConversionMolding:(Class)cls dict:(NSDictionary *)dict {
    SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:cls];
    NSAssert(uM.primaryKey || uM.autoincrementPrimaryKey, @"[%@] 该类没有设置主键", cls);
    const char *tabName = _sjGetTabName(cls);
    
    NSMutableString *fieldsSqlM = [NSMutableString new];
    [fieldsSqlM appendFormat:@"select * from %s where ", tabName];
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [fieldsSqlM appendFormat:@"%@ = '%@'", key, obj];
        [fieldsSqlM appendString:@" and "];
    }];
    [fieldsSqlM deleteCharactersInRange:NSMakeRange(fieldsSqlM.length - 5, 5)];
    [fieldsSqlM appendString:@";"];
    
    FMResultSet *set = [self.database executeQuery:fieldsSqlM];
    NSMutableArray<NSMutableDictionary *> *incompleteData = [NSMutableArray new];
    while ([set next]) {
        [incompleteData addObject:set.resultDictionary.mutableCopy];
    }
    return [self _sjConversionMolding:cls rawStorageData:incompleteData];
}

- (void)_sjConversionModelWithOwnerModel:(id)model dict:(NSDictionary *)dict cKr:(NSArray<SJDBMapCorrespondingKeyModel *>*)cKr aKr:(NSArray<SJDBMapArrayCorrespondingKeysModel *> *)aKr {
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull fields, id  _Nonnull fieldsValue, BOOL * _Nonnull stop) {
        
        __block BOOL continueBool = NO;
        [cKr enumerateObjectsUsingBlock:^(SJDBMapCorrespondingKeyModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ( [fields isEqualToString:obj.correspondingFields] ) {
                NSInteger cPrimaryValue = [fieldsValue integerValue];
                id cmodel = [obj.correspondingCls new];
                NSArray<SJDBMapCorrespondingKeyModel *>*ccKr = [self sjGetCorrespondingKeys:obj.correspondingCls];
                NSArray<SJDBMapArrayCorrespondingKeysModel *> *caKr = [self sjGetArrayCorrespondingKeys:obj.correspondingCls];
                [self _sjConversionModelWithOwnerModel:cmodel dict:[self sjQueryRawStorageData:obj.correspondingCls primaryValue:cPrimaryValue] cKr:ccKr aKr:caKr];
                [model setValue:cmodel forKey:obj.ownerFields];
                continueBool = YES;
                *stop = YES;
            }
        }];
        
        if ( continueBool ) return;
        
        [aKr enumerateObjectsUsingBlock:^(SJDBMapArrayCorrespondingKeysModel * _Nonnull ACKM, NSUInteger idx, BOOL * _Nonnull stop) {
            if ( [fields isEqualToString:ACKM.ownerFields] ) {
                NSData *data = [fieldsValue dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary<NSString *, NSArray<NSNumber *> *> *aPrimaryValues = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                [aPrimaryValues enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSNumber *> * _Nonnull obj, BOOL * _Nonnull stop) {
                    NSMutableArray<id> *ar = [NSMutableArray new];
                    [obj enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        id amodel = [ACKM.correspondingCls new];
                        NSArray<SJDBMapCorrespondingKeyModel *>*ccKr = [self sjGetCorrespondingKeys:ACKM.correspondingCls];
                        NSArray<SJDBMapArrayCorrespondingKeysModel *> *caKr = [self sjGetArrayCorrespondingKeys:ACKM.correspondingCls];
                        [self _sjConversionModelWithOwnerModel:amodel dict:[self sjQueryRawStorageData:ACKM.correspondingCls primaryValue:[obj integerValue]] cKr:ccKr aKr:caKr];
                        [ar addObject:amodel];
                    }];
                    [model setValue:ar forKey:ACKM.ownerFields];
                }];
                continueBool = YES;
                *stop = YES;
            }
        }];
        
        if ( continueBool ) return;
        
        if ( [model respondsToSelector:NSSelectorFromString(fields)] ) {
            [model setValue:fieldsValue forKey:fields];
        }
    }];
}

/*!
 *  查询数据库原始存储数据
 */
- (NSArray<NSDictionary *> *)sjQueryRawStorageData:(Class)cls {
    const char *tabName = _sjGetTabName(cls);
    NSString *sql = [NSString stringWithFormat:@"select *from %s;", tabName];
    FMResultSet *set = [self.database executeQuery:sql];
    NSMutableArray<NSMutableDictionary *> *incompleteData = [NSMutableArray new];
    while ([set next]) {
        [incompleteData addObject:set.resultDictionary.mutableCopy];
    }
    return incompleteData;
}

/*!
 *  查询数据库原始存储数据
 */
- (NSDictionary *)sjQueryRawStorageData:(Class)cls primaryValue:(NSInteger)primaryValue {
    SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:cls];
    NSAssert(uM.primaryKey || uM.autoincrementPrimaryKey, @"[%@] 该类没有设置主键", cls);
    const char *tabName = _sjGetTabName(cls);
    NSString *fields = uM.primaryKey ? uM.primaryKey.ownerFields : uM.autoincrementPrimaryKey.ownerFields;
    NSString *sql = [NSString stringWithFormat:@"select * from %s where %@ = %zd;", tabName, fields, primaryValue];
    FMResultSet *set = [self.database executeQuery:sql];
    NSDictionary *incompleteData = nil;
    while ([set next]) {
        incompleteData = set.resultDictionary.copy;
    }
    return incompleteData;
}

/*!
 *  获取该类主键
 */
- (SJDBMapPrimaryKeyModel *)sjGetPrimaryKey:(Class)cls{
    NSString *key = [self _sjPerformClassMethod:cls sel:@selector(primaryKey) obj1:nil obj2:nil];
    if ( !key ) return nil;
    SJDBMapPrimaryKeyModel *model = [SJDBMapPrimaryKeyModel new];
    model.ownerCls = cls;
    model.ownerFields = key;
    return model;
}

/*!
 *  获取自增主键
 */
- (SJDBMapAutoincrementPrimaryKeyModel *)sjGetAutoincrementPrimaryKey:(Class)cls{
    NSString *key = [self _sjPerformClassMethod:cls sel:@selector(autoincrementPrimaryKey) obj1:nil obj2:nil];
    if ( !key ) return nil;
    SJDBMapAutoincrementPrimaryKeyModel *model = [SJDBMapAutoincrementPrimaryKeyModel new];
    model.ownerCls = cls;
    model.ownerFields = key;
    return model;
}

/*!
 *  获取数组相应键
 */
- (NSArray<SJDBMapArrayCorrespondingKeysModel *> *)sjGetArrayCorrespondingKeys:(Class)cls {
    NSDictionary<NSString *, Class> *keys = [self _sjPerformClassMethod:cls sel:@selector(arrayCorrespondingKeys) obj1:nil obj2:nil];
    if ( !keys ) return NULL;
    NSMutableArray<SJDBMapArrayCorrespondingKeysModel *> *modelsM = [NSMutableArray new];
    [keys enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class  _Nonnull obj, BOOL * _Nonnull stop) {
        SJDBMapArrayCorrespondingKeysModel *model = [SJDBMapArrayCorrespondingKeysModel new];
        model.ownerFields = key;
        model.ownerCls = cls;
        model.correspondingCls = obj;
        model.correspondingPrimaryKey = [self sjGetPrimaryKey:obj];
        model.correspondingAutoincrementPrimaryKey = [self sjGetAutoincrementPrimaryKey:obj];
        [modelsM addObject:model];
    }];
    return modelsM;
}

/*!
 *  获取相应键
 */
- (NSArray<SJDBMapCorrespondingKeyModel *>*)sjGetCorrespondingKeys:(Class)cls {
    NSDictionary<NSString *,NSString *> *keys = [self _sjPerformClassMethod:cls sel:@selector(correspondingKeys) obj1:nil obj2:nil];
    if ( !keys ) return NULL;
    NSMutableArray<SJDBMapCorrespondingKeyModel *> *modelsM = [NSMutableArray new];
    [keys enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        SJDBMapCorrespondingKeyModel *model = [SJDBMapCorrespondingKeyModel new];
        model.ownerCls = cls;
        model.ownerFields = key;
        model.correspondingFields = obj;
        model.correspondingCls = [self _sjGetObjClass:model.ownerCls fields:model.ownerFields];
        [modelsM addObject:model];
    }];
    return modelsM;
}

/*!
 *  执行某个有返回值的类方法
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (id)_sjPerformClassMethod:(Class)cls sel:(SEL)sel obj1:(id)obj1 obj2:(id)obj2 {
    if ( ![(id)cls respondsToSelector:sel] ) return nil;
    return [(id)cls performSelector:sel withObject:obj1 withObject:obj2];
}
#pragma clang diagnostic pop

/*!
 *  获取某个变量的对应的类
 */
- (Class)_sjGetObjClass:(Class)ownerCls fields:(NSString *)fields {
    Ivar ivar = class_getInstanceVariable(ownerCls, [NSString stringWithFormat:@"_%@", fields].UTF8String);
    return _sjGetClass(ivar_getTypeEncoding(ivar));
}

/*!
 *  通过C类型获取类, 前提必须是对象类型
 */
Class _sjGetClass(const char *cType) {
    if ( NULL == cType ) return NULL;
    if ( '@' != cType[0] ) return NULL;
    size_t ctl = strlen(cType);
    // 如果是 id 类型, 目前先跳过.
    if ( 1 == strlen(cType) && '@' == cType[0] ) return NULL;
    if ( '\"' != cType[1] ) return NULL;   // @?
    char *className = malloc(ctl);
    *className = '\0';
    for ( int j = 0 ; j < ctl - 3 ; j ++ ) className[j] = cType[j + 2];
    className[ctl - 3] = '\0';
    Class cls = objc_getClass(className);
    free(className);
    return cls;
}

/*!
 *  获取表名
 */
const char *_sjGetTabName(Class cls) {
    return class_getName(cls);
}

//typedef NS_ENUM(NSUInteger, SJType) {
//    SJType_Integer,
//    SJType_UInteger,
//    SJType_Double,
//    SJType_CharStr,
//    SJType_Obj,
//};

//static SJType _sjGetSJType(Ivar ivar) {
//    const char *CType = ivar_getTypeEncoding(ivar);
//    char first = CType[0];
//    if      ( first == _C_INT ||        //  Int
//              first == _C_SHT ||        //  Short
//              first == _C_LNG_LNG ||    //  Long Long
//              first == _C_BFLD ||       //  bool
//              first == _C_BOOL )        //  BOOL
//        return SJType_Integer;
//    else if ( first == _C_UINT ||       //  Unsigned Int
//              first == _C_USHT ||       //  Unsigned Short
//              first == _C_ULNG_LNG ||   //  Unsigned Long
//              first == _C_ULNG_LNG )    //  Unsigned long long
//        return SJType_UInteger;
//    else if ( first == _C_DBL ||        //  double
//              first == _C_FLT )         //  float
//        return SJType_Double;
//    else if ( first == _C_CHARPTR )     //  char  *
//        return SJType_CharStr;
//    else
//        return SJType_Obj;
//}

/*!
 *  查询类中某个字段的C类型
 */
//static const char *_sjIvarCType(Class cls, const char *ivarName) {
//    if ( NULL == ivarName || NULL == cls ) return NULL;
//    Ivar ivar = class_getInstanceVariable(cls, ivarName);
//    return ivar_getTypeEncoding(ivar);
//}
//
///*!
// *  字典转模型
// */
//static id _sjGetModel(Class cls, NSDictionary *dict) {
//    // 获取所有变量名
//    unsigned int ivarCount = 0;
//    struct objc_ivar **ivarList = class_copyIvarList(cls, &ivarCount);
//    
//    id model = [cls new];
//    for ( int i = 0 ; i < ivarCount ; i++ ) {
//        Ivar ivar = ivarList[i];
//        const char *ivarName = ivar_getName(ivar);
//        id value = dict[[NSString stringWithUTF8String:&ivarName[1]]];
//        
//        SJType type = _sjGetSJType(ivar);
//        switch (type) {
//            case SJType_Integer:
//            case SJType_UInteger:
//            case SJType_Double:
//            {
//                [model setValue:value forKey:[NSString stringWithUTF8String:ivarName]];
//            }
//                break;
//            case SJType_Obj:
//            {
//                const char *oType = _sjIvarCType(cls, ivarName);
//                
//                // NS
//                if ( 'N' == oType[2] && 'S' == oType[3] ) {
//                    [model setValue:value forKey:[NSString stringWithUTF8String:ivarName]];
//                    continue;
//                }
//                
//                size_t ctl = strlen(oType);
//                // id 类型
//                if ( 1 == strlen(oType) && '@' == oType[0] ) {
//                    [model setValue:value forKey:[NSString stringWithUTF8String:ivarName]];
//                    continue;
//                }
//                
//                // @?..@^..
//                if ( '\"' != oType[1] ) {
//                    if ( i == ivarCount - 1) break;
//                    continue;
//                }
//                
//                char *className = malloc(ctl - 4);
//                *className = '\0';
//                for ( int j = 0 ; j < ctl - 3 ; j ++ ) className[j] = oType[j + 2];
//                className[ctl - 3] = '\0';
//                NSString *clsStr = [NSString stringWithUTF8String:className];
//                [model setValue:_sjGetModel(NSClassFromString(clsStr), value) forKey:[NSString stringWithUTF8String:ivarName]];
//                free(className);
//            }
//                break;
//            default:
//                break;
//        }
//    }
//    
//    free(ivarList);
//    
//    return model;
//}
@end