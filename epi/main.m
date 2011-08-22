// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  main.m
//  EasyKit Package Installer
//
//  Created by dan green on 21.08.11.
//  Copyright (c) 2011 TrigenSoftware
//

#import <Foundation/Foundation.h>
#import <SecurityFoundation/SFAuthorization.h>

static AuthorizationRef authRef;
static OSStatus status;
static void initRights();
NSString *runAsRoot(NSString *command, NSArray *args);

int main (int argc, const char * argv[])
{
    printf("Copyright (c) 2011 TrigenSoftware\n");
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    if(argc > 2 && (argc % 2) != 0){ 
        printf("installing was started\n");
        initRights();
        
        for (int i = 1;i < argc-1; i += 2) {
            printf("Proccessing package [%s] at path [%s]\n", argv[i], argv[i+1]);
            printf("%s",[runAsRoot(@"/usr/sbin/installer",[NSArray arrayWithObjects: 
                                                        @"-pkg",
                                                        [NSString stringWithUTF8String:argv[i]],
                                                        @"-target",
                                                        [NSString stringWithUTF8String:argv[i+1]], nil]) UTF8String]);          
           
        } 
      
        printf("end...\n");  
        
    } else printf("usage: epi *.pkg /dev/*\n");
    
    [pool drain];
    return 0;
}

void initRights() 
{
    AuthorizationItem rights[2] = {{"org.epi.epi",  0, NULL, 0 },
        {"system.privilege.admin", 0, NULL, 0}};
    AuthorizationRights rightSet = {2, rights};
    
    
    // Then set needen flags
    AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagPreAuthorize | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
    
    // And do it auth
    status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, flags, &authRef);
    if (status !=errAuthorizationSuccess) {return;}
    
    // Save our right for next time
    status = AuthorizationCopyRights(authRef, &rightSet, kAuthorizationEmptyEnvironment, flags, NULL);
    if (status !=errAuthorizationSuccess) {return;}

}

NSString *runAsRoot(NSString *command, NSArray *args)
{
    // Create an output stream
    FILE* pipe = NULL;
    
    // Prepare arguments
    char* p_args[([args count]) + 1];
    int i = 0;
    while(p_args && i < [args count])
    {
        p_args[i] = (char*)[[args objectAtIndex:i] cStringUsingEncoding:NSASCIIStringEncoding];
        i++;
    }
    p_args[i] = NULL;
    
    // Execute command
    status = AuthorizationExecuteWithPrivileges(authRef,
                                                (char*)[command cStringUsingEncoding:NSASCIIStringEncoding], 
                                                kAuthorizationFlagDefaults, 
                                                p_args, 
                                                &pipe);
    // Read the return of executed command from our stream
    NSMutableString *result = [[NSMutableString alloc] init];
    char tempo[13];
    while (fgets(tempo, 13, pipe)) {
        [result appendFormat:@"%s",tempo];
    }
    fclose(pipe);
    
    if(status == 0) {
        return [result autorelease];
    } else {
        [result release];
        return nil;
    }
}