//
//  main.m
//  EasyKit Package Installer
//
//  Created by dan green on 21.08.11.
//  Copyright 2011 TrigenSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SecurityFoundation/SFAuthorization.h>

static AuthorizationRef authRef;
static OSStatus status;
static void initRights();
NSString *runAsRoot(NSString *command, NSArray *args);

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];    
    if(argc>2 && argc%2!=0){
        initRights();
        printf("Script Started\n");
        
        for(int i=1;i<argc;i+=2){
            printf("installing of %d pare\n%s and %s\n",i,argv[i],argv[i+1]); 
            runAsRoot(@"/usr/sbin/installer",[NSArray arrayWithObjects: @"-pkg",argv[i],@"-target",argv[i+1], nil]);
            //printf("%s\n",[ UTF8String]); 
            //runAsRoot(@"/bin/mkdir", [NSArray arrayWithObjects: @"/stert",nil]);
        }
            
        printf("end...\n");  
    } else printf("nothing to be done\n");
    
    [pool drain];
    return 0;
}

void initRights() 
{
    status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authRef);
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