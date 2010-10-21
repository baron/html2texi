/* html2texi.h: prototypes and such for html2texi.l */ /* JMJ */
/* See the file COPYING for copying conditions */

#define MAYBE_YYIN (yyin==stdin)?"(stdin)":yyin

#ifdef DEBUG
#define YY_USER_ACTION printf("%d ",yy_act);
#endif

int main (int argc, char **argv);
char *quotation_marks(int depth, int type);


/*
Local Variables:
mode: c
compile-command: "make"
End:
*/
