// vi:nu:et:sts=4 ts=4 sw=4

//****************************************************************
//          J1939DL Console Transmit Task (j1939dl) Header
//****************************************************************
/*
 * Program
 *			Separate j1939dl (j1939dl)
 * Purpose
 *			This object provides a standardized way of handling
 *          a separate j1939dl to run things without complications
 *          of interfering with the main j1939dl. A j1939dl may be 
 *          called a j1939dl on other O/S's.
 *
 *          The PGNs associated with the Data Link Layer are:
 *              59904 (Request PG) Used to request a PGN from network device(s)
 *              59392 (Acknowledgement) is used to provide a handshake mechanism
 *                      between transmitting and receiving devices
 *              51456 (Request2) Used to request a PGN from network device or
 *                      devices and to specify whether the response should use
 *                      the Transfer PGN () or not.
 *              51712 (Transfer) Used for transfer of data in response to a
 *                      Request2 (51456) PGN when the "Use Transfer PGN for
 *                      response" is set to "Yes"
 *              60416 (Transport Protocol - Connection Management)
 *              60160 (Transport Protocol - Data Transfer)
 *
 * Remarks
 *	1.      Using this object allows for testable code, because a
 *          function, TaskBody() must be supplied which is repeatedly
 *          called on the internal j1939dl. A testing unit simply calls
 *          the TaskBody() function as many times as needed to test.
 *
 * History
 *	04/14/2017 Generated
 */


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





#include        <j1939_defs.h>
#include        <AStr.h>


#ifndef         J1939DL_H
#define         J1939DL_H



#ifdef	__cplusplus
extern "C" {
#endif
    

    //****************************************************************
    //* * * * * * * * * * * *  Data Definitions  * * * * * * * * * * *
    //****************************************************************


    typedef struct j1939dl_data_s	J1939DL_DATA;    // Inherits from OBJ.

    typedef struct j1939dl_vtbl_s	{
        OBJ_IUNKNOWN    iVtbl;              // Inherited Vtbl.
        // Put other methods below this as pointers and add their
        // method names to the vtbl definition in j1939dl_object.c.
        // Properties:
        // Methods:
        //bool        (*pIsEnabled)(J1939DL_DATA *);
    } J1939DL_VTBL;



    /****************************************************************
    * * * * * * * * * * *  Routine Definitions	* * * * * * * * * * *
    ****************************************************************/


    //---------------------------------------------------------------
    //                      *** Class Methods ***
    //---------------------------------------------------------------

    /*!
     Allocate a new Object and partially initialize. Also, this sets an
     indicator that the object was alloc'd which is tested when the object is
     released.
     @return:   pointer to j1939dl object if successful, otherwise OBJ_NIL.
     */
    J1939DL_DATA *     j1939dl_Alloc(
    );
    
    
    J1939DL_DATA *     j1939dl_New(
    );
    
    

    //---------------------------------------------------------------
    //                      *** Properties ***
    //---------------------------------------------------------------

    ERESULT     j1939dl_getLastError(
        J1939DL_DATA		*this
    );



    
    //---------------------------------------------------------------
    //                      *** Methods ***
    //---------------------------------------------------------------

    ERESULT         j1939dl_Disable(
        J1939DL_DATA	*this
    );


    ERESULT         j1939dl_Enable(
        J1939DL_DATA    *this
    );

   
    J1939DL_DATA *   j1939dl_Init(
        J1939DL_DATA    *this
    );


    ERESULT         j1939dl_IsEnabled(
        J1939DL_DATA	*this
    );
    
 
    /*!
     Create a string that describes this object and the objects within it.
     Example:
     @code:
        ASTR_DATA      *pDesc = j1939dl_ToDebugString(this,4);
     @endcode:
     @param:    this    J1939DL object pointer
     @param:    indent  number of characters to indent every line of output, can be 0
     @return:   If successful, an AStr object which must be released containing the
                description, otherwise OBJ_NIL.
     @warning: Remember to release the returned AStr object.
     */
    ASTR_DATA *     j1939dl_ToDebugString(
        J1939DL_DATA    *this,
        int             indent
    );
    
    

    
#ifdef	__cplusplus
}
#endif

#endif	/* J1939DL_H */

