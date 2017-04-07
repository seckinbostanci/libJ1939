
/*
 This is free and unencumbered software released into the public domain.
 
 Anyone is free to copy, modify, publish, use, compile, sell, or
 distribute this software, either in source code form or as a compiled
 binary, for any purpose, commercial or non-commercial, and by any
 means.
 
 In jurisdictions that recognize copyright laws, the author or authors
 of this software dedicate any and all copyright interest in the
 software to the public domain. We make this dedication for the benefit
 of the public at large and to the detriment of our heirs and
 successors. We intend this dedication to be an overt act of
 relinquishment in perpetuity of all present and future rights to this
 software under copyright law.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 For more information, please refer to <http://unlicense.org/>
 */


#import     <XCTest/XCTest.h>
#import     <cmn_defs.h>
#include    <j1939.h>
#include    "j1939er_internal.h"
#include    "common.h"              // Tests Common Routines
#include    "j1939Can.h"
#include    "j1939Sys.h"


// All code under test must be linked into the Unit Test bundle
// Test Macros:
//      XCTAssert(expression, failure_description, ...)
//      XCTFail(failure_description, ...)
//      XCTAssertEqualObjects(object_1, object_2, failure_description, ...) uses isEqualTo:
//      XCTAssertEquals(value_1, value_2, failure_description, ...)
//      XCTAssertEqualsWithAccuracy(value_1, value_2, accuracy, failure_description, ...)
//      XCTAssertNil(expression, failure_description, ...)
//      XCTAssertNotNil(expression, failure_description, ...)
//      XCTAssertTrue(expression, failure_description, ...)
//      XCTAssertFalse(expression, failure_description, ...)
//      XCTAssertThrows(expression, failure_description, ...)
//      XCTAssertThrowsSpecific(expression, exception_class, failure_description, ...)
//      XCTAssertThrowsSpecificNamed(expression, exception_class, exception_name,
//                                  failure_description, ...)
//      XCTAssertNoThrow(expression, failure_description, ...)
//      XCTAssertNoThrowSpecific(expression, exception_class, failure_description, ...)
//      XCTAssertNoThrowSpecificNamed(expression, exception_class, exception_name,
//                                  failure_description, ...)






@interface j1939erTests : XCTestCase

@end

@implementation j1939erTests


- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each
    // test method in the class.
    
    mem_Init( );
    
}


- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each
    // test method in the class.
    [super tearDown];
    
    mem_Dump( );
}



- (void)testOpenClose_1_0
{
    J1939SYS_DATA   *pSYS = j1939Sys_New();
    J1939CAN_DATA   *pCAN = j1939Can_New(1);
    J1939ER_DATA    *pER = NULL;

    j1939Sys_TimeReset(pSYS, 0);

    pER = j1939er_Alloc();
    XCTAssertFalse( (NULL == pER), @"Could not alloc pER" );
    pER = j1939er_Init(
                       pER,
                       xmtHandler,      // pXmtMsg
                       NULL,            // pXmtData
                       1,              // J1939 Identity Number (21 bits)
                       10,             // J1939 Manufacturer Code (11 bits) (Cummins)
                       4               // J1939 Industry Group (3 bits) (Marine)
            );
    XCTAssertFalse( (NULL == pER), @"Could not init pER" );
    cCurMsg = 0;
    if (pER) {

        obj_Release(pER);
        pER = NULL;
    }
    
    obj_Release(pCAN);
    pCAN = OBJ_NIL;
    obj_Release(pSYS);
    pSYS = OBJ_NIL;
}



- (void)testCheck_RequestNameDirect
{
    J1939SYS_DATA   *pSYS = j1939Sys_New();
    J1939CAN_DATA   *pCAN = j1939Can_New(1);
    J1939ER_DATA    *pJ1939er = NULL;
    bool            fRc;
    J1939_MSG       msg;
    J1939_PDU       pdu;
    uint8_t         data[8];
    
    j1939Sys_TimeReset(pSYS, 0);

    pJ1939er = j1939er_Alloc();
    XCTAssertFalse( (OBJ_NIL == pJ1939er), @"Could not alloc J1939CA" );
    pJ1939er =  j1939er_Init(
                        pJ1939er,
                        xmtHandler,
                        NULL,
                        1,              // J1939 Identity Number (21 bits)
                        10,             // J1939 Manufacturer Code (11 bits) (Cummins)
                        4               // J1939 Industry Group (3 bits) (Marine)
                );
    XCTAssertFalse( (OBJ_NIL == pJ1939er), @"Could not init J1939CA" );
    cCurMsg = 0;
    if (pJ1939er) {

        // Initiate Address Claim.
        fRc = j1939ca_HandlePgn60928((J1939CA_DATA *)pJ1939er, 0, NULL);
        // Send "Timed Out".
        j1939Sys_BumpMS(pSYS, 250);
        fRc = j1939ca_HandlePgn60928((J1939CA_DATA *)pJ1939er, 0, NULL);
        XCTAssertTrue( (J1939CA_STATE_NORMAL_OPERATION == pJ1939er->super.cs), @"" );

        // Setup up msg from #3 Transmission to ER requesting NAME;
        pdu.eid = 0;
        pdu.SA = 3;
        pdu.P = 3;
        pdu.PF = 0xEA;
        pdu.PS = 41;
        for (int i=0; i<8; ++i) {
            data[i] = 0xFF;
        }
        data[0] = 0x00;
        data[1] = 0xEE;
        data[2] = 0x00;
        j1939msg_ConstructMsg_E1(&msg, pdu.eid, 8, data);
        msg.CMSGSID.CMSGTS = 0xFFFF;    // Denote transmitting;
        fRc = xmtHandler(NULL, 0, &msg);
        fRc = j1939ca_HandleMessages( (J1939CA_DATA *)pJ1939er, pdu.eid, &msg );
        XCTAssertTrue( (4 == cCurMsg), @"Result was false!" );
        pdu = j1939msg_getJ1939_PDU(&curMsg[cCurMsg-2]);
        XCTAssertTrue( (0x18EEFF29 == pdu.eid), @"Result was false!" );
        pdu = j1939msg_getJ1939_PDU(&curMsg[cCurMsg-1]);
        XCTAssertTrue( (0x18F00029 == pdu.eid), @"Result was false!" );

        obj_Release(pJ1939er);
        pJ1939er = OBJ_NIL;
    }
    
    obj_Release(pCAN);
    pCAN = OBJ_NIL;
    obj_Release(pSYS);
    pSYS = OBJ_NIL;
}



- (void)testCheck_RequestBadNameDirect
{
    J1939SYS_DATA   *pSYS = j1939Sys_New();
    J1939CAN_DATA   *pCAN = j1939Can_New(1);
    J1939ER_DATA    *pJ1939er = NULL;
    bool            fRc;
    J1939_MSG       msg;
    J1939_PDU       pdu;
    uint8_t         data[8];
    
    j1939Sys_TimeReset(pSYS, 0);

    pJ1939er = j1939er_Alloc();
    XCTAssertFalse( (OBJ_NIL == pJ1939er), @"Could not alloc J1939CA" );
    pJ1939er =  j1939er_Init(
                             pJ1939er,
                             xmtHandler,
                             NULL,
                             1,              // J1939 Identity Number (21 bits)
                             10,             // J1939 Manufacturer Code (11 bits) (Cummins)
                             4               // J1939 Industry Group (3 bits) (Marine)
                             );
    XCTAssertFalse( (OBJ_NIL == pJ1939er), @"Could not init J1939CA" );
    cCurMsg = 0;
    if (pJ1939er) {
        
        // Initiate Address Claim.
        fRc = j1939ca_HandlePgn60928((J1939CA_DATA *)pJ1939er, 0, NULL);
        // Send "Timed Out".
        j1939Sys_BumpMS(pSYS, 250);
        fRc = j1939ca_HandlePgn60928((J1939CA_DATA *)pJ1939er, 0, NULL);
        XCTAssertTrue( (J1939CA_STATE_NORMAL_OPERATION == pJ1939er->super.cs), @"" );
        
        // Setup up msg from #3 Transmission to ER requesting NAME;
        pdu.eid = 0;
        pdu.SA = 3;
        pdu.P = 3;
        pdu.PF = 0xEA;
        pdu.PS = 41;
        for (int i=0; i<8; ++i) {
            data[i] = 0xFF;
        }
        data[0] = 0x00;
        data[1] = 0x23;         // Not Sure what this is! lol
        data[2] = 0x00;
        j1939msg_ConstructMsg_E1(&msg, pdu.eid, 8, data);
        msg.CMSGSID.CMSGTS = 0xFFFF;    // Denote transmitting;
        fRc = xmtHandler(NULL, 0, &msg);
        fRc = j1939ca_HandleMessages( (J1939CA_DATA *)pJ1939er, pdu.eid, &msg );
        XCTAssertTrue( (4 == cCurMsg), @"Result was false!" );
        pdu = j1939msg_getJ1939_PDU(&curMsg[cCurMsg-2]);
        XCTAssertTrue( (0x18E80329 == pdu.eid), @"Result was false!" );
        pdu = j1939msg_getJ1939_PDU(&curMsg[cCurMsg-1]);
        XCTAssertTrue( (0x18F00029 == pdu.eid), @"Result was false!" );
        
        obj_Release(pJ1939er);
        pJ1939er = OBJ_NIL;
    }
    
    obj_Release(pCAN);
    pCAN = OBJ_NIL;
    obj_Release(pSYS);
    pSYS = OBJ_NIL;
}



- (void)testCheck_RequestBadNameGlobal
{
    J1939SYS_DATA   *pSYS = j1939Sys_New();
    J1939CAN_DATA   *pCAN = j1939Can_New(1);
    J1939ER_DATA    *pJ1939er = NULL;
    bool            fRc;
    J1939_MSG       msg;
    J1939_PDU       pdu;
    uint8_t         data[8];
    
    j1939Sys_TimeReset(pSYS, 0);

    pJ1939er = j1939er_Alloc();
    XCTAssertFalse( (OBJ_NIL == pJ1939er) );
    pJ1939er =  j1939er_Init(
                             pJ1939er,
                             xmtHandler,
                             NULL,
                             1,              // J1939 Identity Number (21 bits)
                             10,             // J1939 Manufacturer Code (11 bits) (Cummins)
                             4               // J1939 Industry Group (3 bits) (Marine)
                             );
    XCTAssertFalse( (OBJ_NIL == pJ1939er) );
    cCurMsg = 0;
    if (pJ1939er) {
        
        // Initiate Address Claim.
        fRc = j1939ca_HandlePgn60928((J1939CA_DATA *)pJ1939er, 0, NULL);
        // Send "Timed Out".
        j1939Sys_BumpMS(pSYS, 250);
        fRc = j1939ca_HandlePgn60928((J1939CA_DATA *)pJ1939er, 0, NULL);
        XCTAssertTrue( (J1939CA_STATE_NORMAL_OPERATION == pJ1939er->super.cs), @"" );
        
        // Setup up msg from #3 Transmission to ER requesting NAME;
        pdu.eid = 0;
        pdu.SA = 3;
        pdu.P = 3;
        pdu.PF = 0xEA;
        pdu.PS = 255;
        for (int i=0; i<8; ++i) {
            data[i] = 0xFF;
        }
        data[0] = 0x00;
        data[1] = 0x23;         // Not Sure what this is! lol
        data[2] = 0x00;
        j1939msg_ConstructMsg_E1(&msg, pdu.eid, 8, data);
        msg.CMSGSID.CMSGTS = 0xFFFF;    // Denote transmitting;
        fRc = xmtHandler(NULL, 0, &msg);
        fRc = j1939ca_HandleMessages( (J1939CA_DATA *)pJ1939er, pdu.eid, &msg );
        // It will not nak since we asked globablly.
        XCTAssertTrue( (3 == cCurMsg), @"Result was false!" );
        pdu = j1939msg_getJ1939_PDU(&curMsg[cCurMsg-1]);
        XCTAssertTrue( (0x18F00029 == pdu.eid), @"Result was false!" );
        
        obj_Release(pJ1939er);
        pJ1939er = OBJ_NIL;
    }
    
    obj_Release(pCAN);
    pCAN = OBJ_NIL;
    obj_Release(pSYS);
    pSYS = OBJ_NIL;
}



- (void)testCheck_RequestIRC1Direct
{
    J1939SYS_DATA   *pSYS = j1939Sys_New();
    J1939CAN_DATA   *pCAN = j1939Can_New(1);
    J1939ER_DATA    *pJ1939er = NULL;
    bool            fRc;
    J1939_MSG       msg;
    J1939_PDU       pdu;
    uint8_t         data[8];
    
    j1939Sys_TimeReset(pSYS, 0);

    pJ1939er = j1939er_Alloc();
    XCTAssertFalse( (OBJ_NIL == pJ1939er) );
    pJ1939er =  j1939er_Init(
                             pJ1939er,
                             xmtHandler,
                             NULL,
                             1,              // J1939 Identity Number (21 bits)
                             10,             // J1939 Manufacturer Code (11 bits) (Cummins)
                             4               // J1939 Industry Group (3 bits) (Marine)
                             );
    XCTAssertFalse( (OBJ_NIL == pJ1939er) );
    cCurMsg = 0;
    if (pJ1939er) {
        
        // Initiate Address Claim.
        fRc = j1939ca_HandlePgn60928((J1939CA_DATA *)pJ1939er, 0, NULL);
        // Send "Timed Out".
        j1939Sys_BumpMS(pSYS, 250);
        fRc = j1939ca_HandlePgn60928((J1939CA_DATA *)pJ1939er, 0, NULL);
        XCTAssertTrue( (J1939CA_STATE_NORMAL_OPERATION == pJ1939er->super.cs), @"" );
        
        // Setup up msg from #3 Transmission to ER requesting NAME;
        pdu.eid = 0;
        pdu.SA = 3;
        pdu.P = 3;
        pdu.PF = 0xEA;
        pdu.PS = 41;
        for (int i=0; i<8; ++i) {
            data[i] = 0xFF;
        }
        data[0] = 0;                // IRC1 PGN
        data[1] = 240;
        data[2] = 0x00;
        j1939msg_ConstructMsg_E1(&msg, pdu.eid, 8, data);
        msg.CMSGSID.CMSGTS = 0xFFFF;    // Denote transmitting;
        fRc = xmtHandler(NULL, 0, &msg);
        fRc = j1939ca_HandleMessages( (J1939CA_DATA *)pJ1939er, pdu.eid, &msg );
        XCTAssertTrue( (4 == cCurMsg), @"Result was false!" );
        pdu = j1939msg_getJ1939_PDU(&curMsg[cCurMsg-2]);
        XCTAssertTrue( (0x18F00029 == pdu.eid), @"Result was false!" );
        pdu = j1939msg_getJ1939_PDU(&curMsg[cCurMsg-1]);
        XCTAssertTrue( (0x18F00029 == pdu.eid), @"Result was false!" );
        
        obj_Release(pJ1939er);
        pJ1939er = OBJ_NIL;
    }
    
    obj_Release(pCAN);
    pCAN = OBJ_NIL;
    obj_Release(pSYS);
    pSYS = OBJ_NIL;
}



- (void)testCheck_TimedIRC1
{
    J1939SYS_DATA   *pSYS = j1939Sys_New();
    J1939CAN_DATA   *pCAN = j1939Can_New(1);
    J1939ER_DATA    *pJ1939er = NULL;
    bool            fRc;
    J1939_PDU       pdu;
    
    j1939Sys_TimeReset(pSYS, 0);

    pJ1939er = j1939er_Alloc();
    XCTAssertFalse( (OBJ_NIL == pJ1939er) );
    pJ1939er =  j1939er_Init(
                             pJ1939er,
                             xmtHandler,
                             NULL,
                             1,              // J1939 Identity Number (21 bits)
                             10,             // J1939 Manufacturer Code (11 bits) (Cummins)
                             4               // J1939 Industry Group (3 bits) (Marine)
                             );
    XCTAssertFalse( (OBJ_NIL == pJ1939er) );
    cCurMsg = 0;
    if (pJ1939er) {
        
        // Initiate Address Claim.
        fRc = j1939ca_HandlePgn60928((J1939CA_DATA *)pJ1939er, 0, NULL);
        // Send "Timed Out".
        j1939Sys_BumpMS(pSYS, 250);
        fRc = j1939ca_HandlePgn60928((J1939CA_DATA *)pJ1939er, 0, NULL);
        XCTAssertTrue( (J1939CA_STATE_NORMAL_OPERATION == pJ1939er->super.cs), @"" );
        
        for (int i=0; i<200; ++i) {
            j1939Sys_BumpMS(pSYS, 10);
            fRc = j1939ca_HandleMessages( (J1939CA_DATA *)pJ1939er, 0, NULL );
        }        

        fprintf( stderr, "cCurMsg = %d\n", cCurMsg );
        XCTAssertTrue( (3 == cCurMsg), @"Result was false!" );
        pdu = j1939msg_getJ1939_PDU(&curMsg[cCurMsg-1]);
        XCTAssertTrue( (0x18F00029 == pdu.eid), @"Result was false!" );
        
        obj_Release(pJ1939er);
        pJ1939er = OBJ_NIL;
    }
    
    obj_Release(pCAN);
    pCAN = OBJ_NIL;
    obj_Release(pSYS);
    pSYS = OBJ_NIL;
}



- (void)testCheck_TSC1_Direct_Clean
{
    J1939SYS_DATA   *pSYS = j1939Sys_New();
    J1939CAN_DATA   *pCAN = j1939Can_New(1);
    J1939ER_DATA    *pJ1939er = NULL;
    bool            fRc;
    J1939_MSG       msg;
    J1939_PDU       pdu;
    uint8_t         data[8];
    
    j1939Sys_TimeReset(pSYS, 0);

    pJ1939er = j1939er_Alloc();
    XCTAssertFalse( (OBJ_NIL == pJ1939er) );
    pJ1939er =  j1939er_Init(
                             pJ1939er,
                             xmtHandler,
                             NULL,
                             1,              // J1939 Identity Number (21 bits)
                             10,             // J1939 Manufacturer Code (11 bits) (Cummins)
                             4               // J1939 Industry Group (3 bits) (Marine)
                             );
    XCTAssertFalse( (OBJ_NIL == pJ1939er) );
    cCurMsg = 0;
    if (pJ1939er) {
        
        // Initiate Address Claim.
        fRc = j1939ca_HandlePgn60928((J1939CA_DATA *)pJ1939er, 0, NULL);
        // Send "Timed Out".
        j1939Sys_BumpMS(pSYS, 250);
        fRc = j1939ca_HandlePgn60928((J1939CA_DATA *)pJ1939er, 0, NULL);
        XCTAssertTrue( (J1939CA_STATE_NORMAL_OPERATION == pJ1939er->super.cs), @"" );
        
        // Setup up msg from #3 Transmission to TSC1;
        pdu.eid = 0;
        pdu.SA = 3;
        pdu.P = 3;
        pdu.PF = 0;
        pdu.PS = 41;
        for (int i=0; i<8; ++i) {
            data[i] = 0xFF;
        }
        data[0] = 2;                // Brake
        //data[1] = 240;
        //data[2] = 0x00;
        j1939msg_ConstructMsg_E1(&msg, pdu.eid, 8, data);
        msg.CMSGSID.CMSGTS = 0xFFFF;    // Denote transmitting;
        fRc = xmtHandler(NULL, 0, &msg);
        fRc = j1939ca_HandleMessages( (J1939CA_DATA *)pJ1939er, pdu.eid, &msg );
        XCTAssertTrue( (true == pJ1939er->fActive), @"" );
        XCTAssertTrue( (3 == pJ1939er->spn1480), @"" );

        for (int i=0; i<100; ++i) {
            j1939Sys_BumpMS(pSYS, 10);
            fRc = j1939ca_HandleMessages( (J1939CA_DATA *)pJ1939er, 0, NULL );
        }
        
        // Setup up msg from #3 Transmission to TSC1;
        pdu.eid = 0;
        pdu.SA = 3;
        pdu.P = 3;
        pdu.PF = 0;
        pdu.PS = 41;
        for (int i=0; i<8; ++i) {
            data[i] = 0xFF;
        }
        data[0] = 0;                // Disable Brake
        //data[1] = 240;
        //data[2] = 0x00;
        j1939msg_ConstructMsg_E1(&msg, pdu.eid, 8, data);
        msg.CMSGSID.CMSGTS = 0xFFFF;    // Denote transmitting;
        fRc = xmtHandler(NULL, 0, &msg);
        fRc = j1939ca_HandleMessages( (J1939CA_DATA *)pJ1939er, pdu.eid, &msg );
        XCTAssertTrue( (false == pJ1939er->fActive), @"" );
        XCTAssertTrue( (255 == pJ1939er->spn1480), @"" );
        
        
        fprintf( stderr, "cCurMsg = %d\n", cCurMsg );
        XCTAssertTrue( (5 == cCurMsg), @"Result was false!" );
        pdu = j1939msg_getJ1939_PDU(&curMsg[cCurMsg-2]);
        XCTAssertTrue( (0x18F00029 == pdu.eid), @"Result was false!" );
        pdu = j1939msg_getJ1939_PDU(&curMsg[cCurMsg-1]);
        XCTAssertTrue( (0x0C002903 == pdu.eid), @"Result was false!" );
        
        obj_Release(pJ1939er);
        pJ1939er = OBJ_NIL;
    }
    
    obj_Release(pCAN);
    pCAN = OBJ_NIL;
    obj_Release(pSYS);
    pSYS = OBJ_NIL;
}



- (void)testCheck_TSC1_Direct_Timeout
{
    J1939SYS_DATA   *pSYS = j1939Sys_New();
    J1939CAN_DATA   *pCAN = j1939Can_New(1);
    J1939ER_DATA    *pJ1939er = NULL;
    bool            fRc;
    J1939_MSG       msg;
    J1939_PDU       pdu;
    uint8_t         data[8];
    
    j1939Sys_TimeReset(pSYS, 0);

    pJ1939er = j1939er_Alloc();
    XCTAssertFalse( (OBJ_NIL == pJ1939er), @"Could not alloc J1939CA" );
    pJ1939er =  j1939er_Init(
                             pJ1939er,
                             xmtHandler,
                             NULL,
                             1,              // J1939 Identity Number (21 bits)
                             10,             // J1939 Manufacturer Code (11 bits) (Cummins)
                             4               // J1939 Industry Group (3 bits) (Marine)
                             );
    XCTAssertFalse( (OBJ_NIL == pJ1939er), @"Could not init J1939CA" );
    cCurMsg = 0;
    if (pJ1939er) {
        
        // Initiate Address Claim.
        fRc = j1939ca_HandlePgn60928((J1939CA_DATA *)pJ1939er, 0, NULL);
        // Send "Timed Out".
        j1939Sys_BumpMS(pSYS, 250);
        fRc = j1939ca_HandlePgn60928((J1939CA_DATA *)pJ1939er, 0, NULL);
        XCTAssertTrue( (J1939CA_STATE_NORMAL_OPERATION == pJ1939er->super.cs), @"" );
        
        // Setup up msg from #3 Transmission to TSC1;
        pdu.eid = 0;
        pdu.SA = 3;
        pdu.P = 3;
        pdu.PF = 0;
        pdu.PS = 41;
        for (int i=0; i<8; ++i) {
            data[i] = 0xFF;
        }
        data[0] = 2;                // Brake
        //data[1] = 240;
        //data[2] = 0x00;
        j1939msg_ConstructMsg_E1(&msg, pdu.eid, 8, data);
        msg.CMSGSID.CMSGTS = 0xFFFF;    // Denote transmitting;
        fRc = xmtHandler(NULL, 0, &msg);
        fRc = j1939ca_HandleMessages( (J1939CA_DATA *)pJ1939er, pdu.eid, &msg );
        XCTAssertTrue( (true == pJ1939er->fActive), @"" );
        XCTAssertTrue( (3 == pJ1939er->spn1480), @"" );
        
        for (int i=0; i<200; ++i) {
            j1939Sys_BumpMS(pSYS, 10);
            fRc = j1939ca_HandleMessages( (J1939CA_DATA *)pJ1939er, 0, NULL );
        }
        
        // Setup up msg from #3 Transmission to TSC1;
        pdu.eid = 0;
        pdu.SA = 3;
        pdu.P = 3;
        pdu.PF = 0;
        pdu.PS = 41;
        for (int i=0; i<8; ++i) {
            data[i] = 0xFF;
        }
        data[0] = 0;                // Disable Brake
        //data[1] = 240;
        //data[2] = 0x00;
        j1939msg_ConstructMsg_E1(&msg, pdu.eid, 8, data);
        msg.CMSGSID.CMSGTS = 0xFFFF;    // Denote transmitting;
        fRc = xmtHandler(NULL, 0, &msg);
        fRc = j1939ca_HandleMessages( (J1939CA_DATA *)pJ1939er, pdu.eid, &msg );
        XCTAssertTrue( (false == pJ1939er->fActive), @"" );
        XCTAssertTrue( (255 == pJ1939er->spn1480), @"" );
        
        
        fprintf( stderr, "cCurMsg = %d\n", cCurMsg );
        XCTAssertTrue( (5 == cCurMsg), @"Result was false!" );
        pdu = j1939msg_getJ1939_PDU(&curMsg[cCurMsg-2]);
        XCTAssertTrue( (0x18F00029 == pdu.eid), @"Result was false!" );
        pdu = j1939msg_getJ1939_PDU(&curMsg[cCurMsg-1]);
        XCTAssertTrue( (0x18F00029 == pdu.eid), @"Result was false!" );
        
        obj_Release(pJ1939er);
        pJ1939er = OBJ_NIL;
    }
    
    obj_Release(pCAN);
    pCAN = OBJ_NIL;
    obj_Release(pSYS);
    pSYS = OBJ_NIL;
}



@end


