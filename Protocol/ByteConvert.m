//
//  ByteConvert.m
//  车精灵
//
//  Created by apple on 15/5/14.
//  Copyright (c) 2015年 无锡锐祺. All rights reserved.
//

#import "ByteConvert.h"

@implementation ByteConvert

+ (int)  bytesToUint:(Byte[]) array {
    return ((long) (array[3] & 0xff))
    | ((long) (array[2] & 0xff)) << 8
    | ((long) (array[1] & 0xff)) << 16
    | ((long) (array[0] & 0xff)) << 24;
}

+ (int)  bytesToUshort:(Byte[]) b offset:(int) offset {
    return    (b[offset+1] & 0xff)
    | (b[offset]   & 0xff) << 8;
}

+ (int) bytesToUshort:(Byte[]) b {
    return    (b[1] & 0xff)
    | (b[0] & 0xff) << 8;
}
// char 类型、 float、double 类型和 byte[] 数组之间的转换关系还需继续研究实现。

+ (int) getBitValue:(int) num index:( int) index
{
    return (num & (0x1 << index)) >> index;
}

+(NSData*) shortToBytes:(int) n {
    unsigned char b[2];
    b[1] = (Byte) ( n       & 0xff);
    b[0] = (Byte) ((n >> 8) & 0xff);
    return [[NSData alloc] initWithBytes:b length:2];
}

+(NSData*) intToBytes:(int) n {
    unsigned char b[4];
    b[3] = (Byte) ( n       & 0xff);
    b[2] = (Byte) ((n >> 8) & 0xff);
    b[1] = (Byte) ((n >> 16) & 0xff);
    b[0] = (Byte) ((n >> 24) & 0xff);
    return [[NSData alloc] initWithBytes:b length:4];
}
@end
