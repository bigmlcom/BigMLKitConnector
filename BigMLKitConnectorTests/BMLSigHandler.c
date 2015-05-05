//
//  BMLSigHandler.c
//  BigMLKitConnector
//
//  Created by sergio on 05/05/15.
//  Copyright (c) 2015 BigML Inc. All rights reserved.
//

#include "BMLSigHandler.h"
#include <sys/signal.h>

void sigHandler(int sig) {
    
    printf("SigHandler called!!!");
}

void installSigHandler() {
    
    printf("INSTALLING HANDLERS");
    
    signal(SIGABRT, sigHandler);
    signal(SIGILL, sigHandler);
    signal(SIGSEGV, sigHandler);
    signal(SIGFPE, sigHandler);
    signal(SIGBUS, sigHandler);
    signal(SIGPIPE, sigHandler);
}