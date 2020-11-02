/*****************************************************************************
  ZXText2P.c - ASCII text file to ZX81 emulator .P file

  By Chris Cowley <ccowley@grok.co.uk>

  Portions of this code were taken from zmakebas
    (public domain by Russell Marks)
  
  Copyright (c)2002 Chris Cowley.  <ccowley@grok.co.uk>

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.


  COMPILING
     gcc       - Use "gcc -lm zxtext2p.c".
	 VC++      - Open zxtext2p.c, create a default workspace, press F7 to
	             build.
	 Turbo C++ - Open zxtext2p.c, change MAX_LABELS to 512, set Memory Model
	             to "Small" select Compile->Make EXE file.

 *****************************************************************************/

#define DEFAULT_OUT_FILE    "out.p"
#define MAX_LABEL_LEN       32
#define MAX_LABELS          2000


#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#ifdef HAVE_GETOPT
    #include <unistd.h>
#endif
#include <math.h>
#include <ctype.h>

#ifndef TRUE
    #define TRUE -1
#endif

#ifndef FALSE
    #define FALSE 0
#endif

int iStartLineNum = 10, iLineInc=2;
char sInFile[256], sOutFile[256];
int UseLabels = FALSE;
int labelend=0;
unsigned char labels[MAX_LABELS][MAX_LABEL_LEN+1];
int label_lines[MAX_LABELS];
unsigned char filebuf[32768];
unsigned char sysvarbuf[116]; /* Buffer for holding the system variables */


#define REM_TOKEN_NUM   234

char *tokens[]= {
    "copy", "",
    "return", "",
    "clear", "",
    "unplot", "",
    "cls", "",
    "if", "",
    "randomize", "rand",
    "save", "",
    "run", "",
    "plot", "",
    "print", "",
    "poke", "",
    "next", "",
    "pause", "",
    "let", "",
    "list", "",
    "load", "",
    "input", "",
    "go sub", "gosub",
    "go to", "goto",
    "for", "",
    "rem", "",
    "dim", "",
    "continue", "cont",
    "scroll", "",
    "new", "",
    "fast", "",
    "slow", "",
    "stop", "",
    "llist", "",
    "lprint", "",
    "step", "",
    "to", "",
    "then", "",
    "<>", "",
    ">=", "",
    "<=", "",
    "and", "",
    "or", "",
    "**", "",
    "not", "",
    "chr$", "",
    "str$","",
    "usr","",
    "peek", "",
    "abs", "",
    "sgn", "",
    "sqr", "",
    "int", "",
    "exp", "",
    "ln", "",
    "atn", "",
    "acs", "",
    "asn", "",
    "tan", "",
    "cos", "",
    "sin", "",
    "len", "",
    "val", "",
    "code", "",
    "", "",         /* token 195 - not used */
    "tab", "",
    "at", "",
    "", "",         /* ZX81 escaped-quote char */
    "pi", "",       /* The codes for PI, INKEY$ and RND are just placeholders. */
    "inkey$", "",   /* They get translated into the appropriate ZX81 tokens by */
    "rnd", "",      /* the ASCIIToZXChar() function */
    NULL
};


#ifndef HAVE_GETOPT
    /*
     * getopt()
     *
     * If there is no getopt function available, use this simple
     * work-alike (taken from zmakebas, public domain by Russell Marks
     */
    int optopt=0, opterr=0, optind=1;
    char *optarg=NULL;

    /* holds offset in current argv[] value */
    static unsigned int optpos=1;

    /* This routine assumes that the caller is pretty sane and doesn't
     * try passing an invalid 'optstring' or varying argc/argv.
     */
    int getopt(int argc,char *argv[],char *optstring)
    {
        char *ptr;

        /* check for end of arg list */
        if(optind==argc || *(argv[optind])!='-' || strlen(argv[optind])<=1)
            return(-1);

        if((ptr=strchr(optstring,argv[optind][optpos]))==NULL)
            return('?');        /* error: unknown option */
        else
        {
            optopt=*ptr;
            if(ptr[1]==':')
            {
                if(optind==argc-1) return(':'); /* error: missing option */
                optarg=argv[optind+1];
                optpos=1;
                optind+=2;
                return(optopt); /* return early, avoiding the normal increment */
            }
        }

        /* now increment position ready for next time.
         * no checking is done for the end of args yet - this is done on
         * the next call.
         */
        optpos++;
        if(optpos>=strlen(argv[optind]))
        {
            optpos=1;
            optind++;
        }

        return(optopt);     /* return the found option */
    }
#endif  /* !HAVE_GETOPT */


/*
 * ShowUsage()
 *
 * Displays usage text in response to the '-h' help option
 *
 */
void ShowUsage()
{
    printf("\nusage: zxtext2p [-h] [-i incr] [-l] [-o output-file] [-s line] [input-file]\n\n");
    
    printf("        -h      show this help information.\n");
    printf("        -i      in labels mode, set line number increment. (default = 2).\n");
    printf("        -l      use labels rather than line numbers.\n");
    printf("        -o      specify output file (default `%s').\n",DEFAULT_OUT_FILE);
    printf("        -s      in labels mode, set starting line number (default = 10).\n");
}


/* 
 * ParseOptions()
 *
 * Process the command line options
 *
 */
void ParseOptions(int argc,char *argv[])
{
    int done = 0;

    opterr=0;

    do {
        switch(getopt(argc,argv,"a:hi:ln:o:rs:"))
        {
            case 'h':   /* usage help */
                ShowUsage();
                exit(1);
            case 'i':  /* increment (for labels mode) */
                iLineInc = atoi(optarg);
                if ( iLineInc<1 || iLineInc>9990 ) {
                    fprintf(stderr,"Label line incr. must be in the range 1 to 9990.\n");
                    exit(1);
                }
                break;
            case 'l': /* enable labels mode (off by default) */
                UseLabels = TRUE;
                break;
            case 'o': /* specify output file */
                strcpy(sOutFile,optarg);
                break;
            case 's': /* start line number (for labels mode) */
                iStartLineNum = atoi(optarg);
                if(iStartLineNum<0 || iStartLineNum>9999) {
                    fprintf(stderr,"Label start line must be in the range 0 to 9999.\n");
                    exit(1);
                }
                break;
            case '?':
                switch(optopt) {
                    case 'i':
                        fprintf(stderr,"The `i' option takes a line increment argument.\n");
                        break;
                    case 'o':
                        fprintf(stderr,"The `o' option takes a filename argument.\n");
                        break;
                    case 's':
                        fprintf(stderr,"The `s' option takes a line number argument.\n");
                        break;
                    default:
                        fprintf(stderr,"Option `%c' not recognised.\n",optopt);
                }
                exit(1);
            case -1:
                done = TRUE;
                break;
        }
    } while(!done);

    if(optind<argc-1) {
        /* two or more remaining args */
        ShowUsage();
        exit(1);
    }

    if(optind==argc-1)  {
        /* one remaining arg */
        strcpy(sInFile,argv[optind]);
    }
}


/*
 * BlockGraphic()
 *
 * Handles an escaped 2-character block graphic, returning the appropriate
 * ZX81 character code for the graphic.
 *
 * IN:      &ptr - pointer to an array of characters containing the graphic
 * IN:      iInputLineNum - Line number of input file, used when reporting
 *                          errors
 * RETURN:  ZX81 character code for the specified graphic
 *
 */
int BlockGraphic(unsigned char *ptr,int iInputLineNum)
{
    static char *lookup[] = {
        "  ",   "' ",   " '",   "''",   ". ",   ": ",   ".'",   ":'",   "##",   ",,",   "~~",
        "::",   ".:",   ":.",   "..",   "':",   " :",   "'.",   " .",   "@@",   ";;",   "!!",
        NULL
    };

    char **lptr;
    int f=0, v=-1;
            
    for( lptr=lookup;*lptr!=NULL;lptr++,f++ ) {
        if(strncmp(ptr+1,*lptr,2)==0) {
            v=f;
            break;
        }
    }

    if(v==-1) {
        fprintf(stderr,"line %d: invalid block graphics escape\n",iInputLineNum);
        exit(1);
    }

    if( v>10 ) v+=117;

    return(v);
}


/*
 * dbl2zx81()
 *
 * Converts a double to an inline-basic-style ZX81 floating point number.
 *
 * IN:      num  - Number to convert
 * OUT:     &exp - Exponent
 * OUT:     &man - Mantissa
 * RETURN:  1 if ok, 0 if exponent too big
 *
 */
int dbl2zx81(double num,int *pexp,unsigned long *pman)
{
    int exp;
    unsigned long man;

    /* Special case for zero */
    if (num == 0) {
        exp = man = 0;
        *pexp=exp;
        *pman=man;
        return(1);
    }
    
    /* If negative work with the absolute value */
    if (num < 0)  num = -num;

    exp = (int)floor( log(num)/log(2) );

    if (exp < -129 || exp > 126) return 0;

    man = (unsigned long) floor ( (num/pow(2,exp) - 1) * 0x80000000 + 0.5);
     /* The sign bit is always reset, even for negative numbers,
        which seems like a bit of waste */
    man = man & 0x7fffffff;
    
    /* Adjust the exponent for storage */
    exp += 129;

    *pexp=exp; *pman=man;
    return(1);
}


/*
 * ASCIIToZXChar()
 *
 * IN:      c - ASCII character to convert
 * IN:      iLineNum - Line number of input file, used when reporting errors
 * RETURN:  ZX81 character code
 *
 */
unsigned char ASCIIToZXChar(unsigned char c,int iLineNum)
{
    c = tolower(c);
    if ( c >= 'a' && c <= 'z' ) return (c-59); /* A to Z */
    if ( c >= '0' && c <= '9' ) return (c-20); /* 0 to 9 */

    switch( tolower(c) ) {
    case ' ': return 0;
    case '"': return 11;
    case '#': return 12; /* map '#' to the ZX81 pound symbol */
    case '$': return 13;
    case '(': return 16;
    case ')': return 17;
    case '*': return 23;
    case '+': return 21;
    case ',': return 26;
    case '-': return 22;
    case '.': return 27;
    case '/': return 24;
    case ':': return 14;
    case ';': return 25;
    case '<': return 19;
    case '=': return 20;
    case '>': return 18;
    case '?': return 15;
    case 191: return 66; /* Replace the PI placeholder */
    case 190: return 65; /* Replace the INKEY$ placeholder */
    case 189: return 64; /* Replace the RND placeholder */

    case '!': case '%': case '&':
    case  39: case '@':
        fprintf(stderr,"line %d: Non-mappable character in input\n",iLineNum);
        exit(1);
    }   

    return (c); /* It's a token, return the code unmodified */
}


/*
 * main()
 *
 * Process any command line options
 * Open the input file
 * Read and process it, writing the tokenized output to filebuf
 * Write out a p file using the contents of filebuf
 *
 */
int main(int argc,char *argv[])
{
    FILE *fIn=stdin, *fOut=stdout;
    int iInputLineNum = 0;
    int iPassNum = 1;
    static unsigned char buf[1024],lcasebuf[1024],outbuf[2048];
    int iLineNum = 0, iLastLineNum = 0, iFirstLineNum = -1;
    int iTemp, in_quotes, toknum, toklen, alttok, in_rem;
    unsigned char *ptr, *linestart, *ptrLowCase, *remptr, *outptr, *fileptr;
    char **tarrptr;
    
    double num;
    int num_exp;
    unsigned long num_mantissa;
    
    strcpy(sInFile,"");
    strcpy(sOutFile,DEFAULT_OUT_FILE);

    fileptr=filebuf;

    ParseOptions(argc,argv);

    if( strcmp(sInFile,"") != 0  &&  (fIn=fopen(sInFile,"r"))==NULL) {
        fprintf(stderr,"Could not open input file.\n");
        exit(1);
    }
    
    /* Read and parse the input file
     *
     * There is one pass made if using line numbers
     * and two passes if using labels
     */
    do {
        if( UseLabels ) iLineNum = iStartLineNum - iLineInc;

        if( iPassNum>1 && fseek(fIn,0L,SEEK_SET) !=0 ) {
            fprintf(stderr,"Need seekable input for label support\n");
            exit(1);
        }
  
        while( fgets(buf+1,sizeof(buf)-1,fIn) != NULL ) {
            buf[0]=32;      /* just in case, for all the ptr[-1] stuff */
            iInputLineNum++;
            iLastLineNum=iLineNum;
    
            if(buf[strlen(buf)-1]=='\n') buf[strlen(buf)-1]=0;
    
            /* allow for (shell-style) comments which don't appear in the program,
             * and also ignore blank lines.
             */
            if(buf[1]==0 || buf[1]=='#') continue;
    
            /* check for line continuation */
            while(buf[strlen(buf)-1]=='\\') {
                iTemp = strlen(buf)-1;
                fgets(buf+iTemp,sizeof(buf) - iTemp, fIn);
                iInputLineNum++;
                if(buf[strlen(buf)-1]=='\n') buf[strlen(buf)-1]=0;
            }
    
            if(strlen(buf)>=sizeof(buf)-MAX_LABEL_LEN-1) {
                /* this is nasty, but given how the label substitution works it's
                 * probably the safest thing to do.
                 */
                fprintf(stderr,"line %d: line too big for input buffer\n",iInputLineNum);
                exit(1);
            }
    
            /* get line number (or assign one) */
            if(UseLabels) {
                linestart = buf;
                /* assign a line number */
                iLineNum += iLineInc;

                 /* Remember the first line number for use when writing out the sysvars */
                if (iFirstLineNum == -1) iFirstLineNum = iLineNum;

                if(iLineNum>9999) {
                    fprintf(stderr,"Generated line number is >9999 - %s\n",
                            (iLineInc>1) ? "try using `-s 1 -i 1'" : "too many lines!");
                    exit(1);
                }
            }
            else {
                ptr=buf;
                while ( isspace(*ptr) ) ptr++; /* Trim any leading spaces from the line */
                if ( !isdigit(*ptr) ) {
                    fprintf(stderr,"line %d: missing line number\n",iInputLineNum);
                    exit(1);
                }
                iLineNum = strtol(ptr,(char **)&linestart,10);

                /* Remember the first line number for use when writing out the sysvars */
                if (iFirstLineNum == -1) iFirstLineNum = iLineNum;

                if(iLineNum<=iLastLineNum) {
                    fprintf(stderr,"line %d: line no. not greater than previous one\n",
                    iInputLineNum);
                    exit(1);
                }
            }

            if( iLineNum<0 || iLineNum>9999 ) {
                fprintf(stderr,"line %d: line no. out of range\n",iInputLineNum);
                exit(1);
            }

            /* lose any spaces between line number and the start of the BASIC statement */
            while(isspace(*linestart)) linestart++;
    
            /* check there's no line numbers on label-using programs */
            if(UseLabels && isdigit(*linestart)) {
                fprintf(stderr,"line %d: line number used in labels mode\n",iInputLineNum);
                exit(1);
            }

            /* If this is a label-defining line... */
            if ( UseLabels && *linestart=='@' ) {
                if ( (ptr=strchr(linestart,':'))==NULL ) {
                    fprintf(stderr,"line %d: incomplete label definition\n",iInputLineNum);
                    exit(1);
                }

                if(ptr-linestart-1>MAX_LABEL_LEN) {
                    fprintf(stderr,"line %d: label too long\n",iInputLineNum);
                    exit(1);
                }

                if(iPassNum==1) {
                    *ptr=0;
                    label_lines[labelend]=iLineNum;
                    strcpy(labels[labelend++],linestart+1);
                    if(labelend>=MAX_LABELS) {
                        fprintf(stderr,"line %d: too many labels\n",iInputLineNum);
                        exit(1);
                    }
                    for(iTemp=0;iTemp<labelend-1;iTemp++)
                        if(strcmp(linestart+1,labels[iTemp])==0) {
                            fprintf(stderr,"line %d: attempt to redefine label\n",iInputLineNum);
                            exit(1);
                        }
                    *ptr=':';
                }
      
                linestart = ptr+1;
                while(isspace(*linestart)) linestart++;
      
                /* if now blank, don't bother inserting an actual line here;
                 * instead, fiddle linenum so the next line will have the
                 * same number.
                 */
                if(*linestart==0) {
                    iLineNum -= iLineInc;
                    continue;
                }
            }
    
            if(UseLabels && iPassNum==1) continue;

            /* Make token comparison copy of line. This has lowercase letters and
             * blanked-out strings.
             */
            ptr=linestart; in_quotes=0;
            ptrLowCase=lcasebuf;
            while(*ptr) {
                if(*ptr=='"') in_quotes=!in_quotes;
                if(in_quotes && *ptr!='"')
                    *ptrLowCase++=32;
                else
                    *ptrLowCase++=tolower(*ptr);
                ptr++;
            }
            *ptrLowCase=0;

            /* We now have: linestart == start of the line excluding any line number
                            ptrLowCase == start of a lower-case blank-string copy of the above
                            iLineNum == The line number of this line
                            ptr = a working temp pointer */



            /* now convert any token without letters either side to the correct
             * ZX81 token number. (Any space this leaves in the string is replaced
             * by 0x01 chars.)
             *
             * However, we need to check for REM first. If found, no token/num stuff
             * is performed on the line after that point.
             */
            remptr=NULL;
    
            if ( (ptr=strstr(lcasebuf,"rem")) !=NULL &&
                !isalpha(ptr[-1]) && !isalpha(ptr[3]) ) {

                ptrLowCase=linestart+(ptr-lcasebuf);
                /* endpoint for checks must be here, then. */
                remptr = ptrLowCase;
                *remptr=*ptr=0;
                /* the zero will be replaced with the REM token later */
                ptrLowCase[1]=ptr[1]=ptrLowCase[2]=ptr[2] = 1;
                /* absorb at most one trailing space */
                if(ptr[3]==' ') ptrLowCase[3]=ptr[3]=1;
            }
    
            toknum = 256; alttok = 1;
            for(tarrptr=tokens;*tarrptr!=NULL;tarrptr++) {
                if(alttok) toknum--;
                alttok=!alttok;
                if(**tarrptr==0) continue;
                toklen=strlen(*tarrptr);
                ptr=lcasebuf;

                while((ptr=strstr(ptr,*tarrptr))!=NULL) {
                    /* check it's not in the middle of a word etc., except for
                     * <>, <=, >=.
                     */
                    if ( (*tarrptr)[0]=='<' || (*tarrptr)[1]=='=' ||
                        (!isalpha(ptr[-1]) && !isalpha(ptr[toklen])) ) {
                        ptrLowCase=linestart+(ptr-lcasebuf);
                        /* the token text is overwritten in the lcase copy too, to
                         * avoid problems with e.g. go to/to.
                         */
                        *ptrLowCase=*ptr=toknum;
                        for(iTemp = 1; iTemp < toklen; iTemp++) ptrLowCase[iTemp] = ptr[iTemp] = 1;
                        /* absorb trailing spaces too */
                        while(ptrLowCase[iTemp]==' ') ptrLowCase[iTemp++]=1;
                    }        
                    ptr+=toklen;
                }
            }


            /* Okay, now both the buf, and lcasebuf are tokenized */

            if(UseLabels) {
                /* replace @label with matching number.
                 * this expands labels in strings too, since:
                 * 1. it seems reasonable to assume you might want this;
                 * 2. it makes the code a bit simpler :-) ;
                 * 3. you can use the escape `\@' to get a literal `@' anyway.
                 */
                ptr=linestart;
                while((ptr=strchr(ptr,'@'))!=NULL) {
                    if(ptr[-1]=='\\') {
                        ptr++;
                        continue;
                    }
                
                    /* the easiest way to spot them is to try matching against
                     * each label in turn. It's gross, but at least it's sane
                     * and doesn't restrict what you can have as a label.
                     * We also test that the char after a match is not a printable
                     * ascii char (other than space or colon), to prevent matches
                     * against the shorter of two possibilities.
                     */
                    ptr++;
                    for(iTemp=0; iTemp<labelend; iTemp++) {
                        int len=strlen(labels[iTemp]);
                        if( memcmp(labels[iTemp],ptr,len)==0 &&
                                (ptr[len]<33 || ptr[len]>126 || ptr[len]==':')) {
                            unsigned char numbuf[20];
            
                            /* this could be optimised to use a single memmove(), but
                             * at least this way it's clear(er) what's happening.
                             */
                            /* switch text for label. first, remove text */
                            memmove(ptr-1,ptr+len,strlen(ptr+len)+1);
                            /* make number string */
                            sprintf(numbuf,"%d",label_lines[iTemp]);
                            len=strlen(numbuf);
                            /* insert room for number string */
                            ptr--;
                            memmove(ptr+len,ptr,strlen(ptr)+1);
                            memcpy(ptr,numbuf,len);
                            ptr+=len;
                            break;
                        }
                    }
                    if( iTemp==labelend ) {
                        fprintf(stderr,"line %d: undefined label\n",iInputLineNum);
                        exit(1);
                    }
                }
            }
    
            if(remptr) *remptr=REM_TOKEN_NUM;

            /* remove 0x01s, deal with escapes, and add numbers */
            ptr=linestart;
            outptr=outbuf;
            in_rem=in_quotes=0;
    
            while(*ptr) {
                if(outptr>outbuf+sizeof(outbuf)-10) {
                    fprintf(stderr,"line %d: line too big\n",iInputLineNum);
                    exit(1);
                }
      
                if(*ptr=='"') in_quotes=!in_quotes;
      
                /* as well as 0x01 chars, we skip tabs. */
                if(*ptr==1 || *ptr==9 || (!in_quotes && !in_rem && *ptr==' ')) {
                    ptr++;
                    continue;
                }
      
                if(*ptr==REM_TOKEN_NUM) in_rem=1;

                /* Handle inverse video escape (prefix '%') */
                if(!in_rem && *ptr=='%') {
                    *outptr ++= ASCIIToZXChar(ptr[1],iInputLineNum) | 128;
                    ptr+=2;
                    continue;
                }

      
                /* Handle escaped characters (block graphics and quote char) */
                if(!in_rem && *ptr=='\\') {
                    switch(ptr[1]) {
                        case '"':	*outptr++=192;	break;
                        case '\'': case '.': case ':': case ' ': /* block graphics char */
                        case '~': case ',': case '#': case '@': case ';': case '!':
                            *outptr++=BlockGraphic(ptr,iInputLineNum);
                            ptr++;
                            break;
                        default:
                            fprintf(stderr,"line %d: warning: unknown escape `%c', inserting literally\n",
                                    iInputLineNum,ptr[1]);
                            *outptr++=ptr[1];
                    }
                    ptr+=2;
                    continue;
                }
      
                /* spot any numbers (because we have to add the inline FP
                 * representation). We do this largely by relying on strtod(),
                 * so that we only have to find the start - i.e. a non-alpha char,
                 * an optional `-' or `+', an optional `.', then a digit.
                 */
                if( !in_rem && !in_quotes && !isalpha(ptr[-1]) &&
                    (isdigit(*ptr) ||
                    ((*ptr=='-' || *ptr=='+' || *ptr=='.') && isdigit(ptr[1])) ||
                    ((*ptr=='-' || *ptr=='+') && ptr[1]=='.' && isdigit(ptr[2]))))
                {
                    /* we have a number. parse with strtod(). */
                    num=strtod(ptr,(char **)&ptrLowCase);
        
                    /* output text of number */
                    while (ptr<ptrLowCase)
                        *outptr++=ASCIIToZXChar(*ptr++,iInputLineNum);
                                
                    *outptr++=0x7e;
                    if(!dbl2zx81(num,&num_exp,&num_mantissa)) {
                        fprintf(stderr,"line %d: exponent out of range (number too big)\n",
                                iInputLineNum);
                        exit(1);
                    }
                    *outptr ++= num_exp;
                    *outptr ++= (unsigned char) (num_mantissa>>24);
                    *outptr ++= (unsigned char) (num_mantissa>>16);
                    *outptr ++= (unsigned char) (num_mantissa>>8);
                    *outptr ++= (unsigned char) (num_mantissa&255);
                    ptr = ptrLowCase;
                }
                else {
                    /* if not number, just output char */
                    *outptr++=ASCIIToZXChar(*ptr++,iInputLineNum);
                }
            }
    
            *outptr++=0x76; /* add terminating NEWLINE */


            /* output line */
            iTemp=outptr-outbuf;
            if(fileptr+4+iTemp>=filebuf+sizeof(filebuf)) {
                /* the program would be too big to load into a ZX81 long before
                 * you'd get this error, but FWIW...
                 */
                fprintf(stderr,"program too big!\n");
                exit(1);
            }
            *fileptr++=(iLineNum>>8);
            *fileptr++=(iLineNum&255);
            *fileptr++=(iTemp&255);
            *fileptr++=(iTemp>>8);
            memcpy(fileptr,outbuf,iTemp);
            fileptr+=iTemp;


        } /* while */

        iPassNum++;
    } while( UseLabels && iPassNum<=2); /* end of do..while() pass loop */
    
    if ( fIn != stdin ) fclose(fIn);


    /* write the output file */

    if( strcmp(sOutFile,"-") != 0 && (fOut=fopen(sOutFile,"wb")) == NULL ) {
        fprintf(stderr,"Couldn't open output file.\n");
        exit(1);
    }

  
    /*
    ** make sysvars: 116 bytes from 0x4009 (16393) to 16509
    */
    iTemp = fileptr-filebuf + 0x407D; /* iTemp = Address of D_FILE */
    memset(sysvarbuf,0,116);

    /* E_PPC    - Line number of line which has the edit cursor */
    sysvarbuf[1]=iFirstLineNum & 255;   
    sysvarbuf[2]=iFirstLineNum>>8;   /* E_PPC  high */
    /* D_FILE   - Address of display file */
    sysvarbuf[3]=iTemp & 255;   
    sysvarbuf[4]=iTemp++>>8;
    /* DF_CC    - Address of print position in display file */
    sysvarbuf[5]=iTemp & 255;   
    sysvarbuf[6]=iTemp>>8;
    iTemp += 792; /* iTemp = Address of VARS area */
    /* VARS     - Address of program variables */
    sysvarbuf[7]=iTemp & 255;
    sysvarbuf[8]=iTemp++>>8;
    /* E_LINE   - Pointer to line edit buffer */
    sysvarbuf[11]=iTemp & 255;
    sysvarbuf[12]=iTemp++>>8;
    /* CH_ADD   - Address of the next character to be interpreted */
    sysvarbuf[13]=iTemp & 255;
    sysvarbuf[14]=iTemp++>>8;
    /* STKBOT   - Points to the bottom of the calculator stack AND...
       STKEND   - Points to the end of the calculator stack */
    sysvarbuf[17]=sysvarbuf[19]=iTemp & 255;
    sysvarbuf[18]=sysvarbuf[20]=iTemp>>8;
    /* MEM      - Address of area used for calculator's memory (we point this at MEMBOT 0x405D */
    sysvarbuf[22]=0x5d;  
    sysvarbuf[23]=0x40;
    /* DF_SZ       - Number of lines (including 1 blank line) in lower part of the screen */
    sysvarbuf[25]=2;
    /* LAST_K      - Shows which keys are pressed */
    sysvarbuf[28]=255;  
    sysvarbuf[29]=255;
    /* DEBOUNCE    - Debounce status of keyboard */
    sysvarbuf[30]=0x0f;
    /* MARGIN      - Number of scanlines before start of display (55=PAL, 31=NTSC) */
    sysvarbuf[31]=55;
    sysvarbuf[32]=0x7d; /*sysvarbuf[3];  /* NXTLIN low  - Address of next program line to be executed */
    sysvarbuf[33]=0x40; /*sysvarbuf[4];  /* NXTLIN high */
    /* T_ADDR      - Address of next item in syntax table */
    sysvarbuf[39]=0x6b;  
    sysvarbuf[40]=0x0c;
    /* FRAMES      - Seed for random number generation. Set by RAND */
    sysvarbuf[43]=0x7d;  
    sysvarbuf[44]=0xfd;
    /* PR_CC       - Least significant byte of address of next position for LPRINT to print */
    sysvarbuf[47]=0xbc;
    /* S_POSN x    - Column number for print position */
    sysvarbuf[48]=0x21;
    /* S_POSN y    - Row number for print position */
    sysvarbuf[49]=0x18;
    /* CDFLAG      - Various flags. Bit 7 is set during SLOW mode, Bit 6 is the true fast/slow flag */
    sysvarbuf[50]=0x40;
    /* PRBUF      - Printer buffer (33 bytes, 33rd is NEWLINE) */
    sysvarbuf[83]=118;


    /* write the system variables */
    fwrite(sysvarbuf,1,116,fOut);

    /* write the program data */  
    fwrite(filebuf,1,fileptr-filebuf,fOut);

    /* Write an empty DFILE area */
    memset(sysvarbuf,0,33);
    sysvarbuf[0]=118;
    sysvarbuf[33]=118;
    fwrite (sysvarbuf,1,1,fOut); /* Initial HALT */

    for(iTemp=1;iTemp<25;iTemp++)
        fwrite(&sysvarbuf[1],1,33,fOut); /* 24 lines of D_FILE data */
    

    /* Write and empty VARS area */
    sysvarbuf[0]=0x80;
    sysvarbuf[1]=0x76;
    fwrite (sysvarbuf,1,2,fOut);


    if(fOut!=stdout) fclose(fOut);

    return(0);
}
