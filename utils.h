/* utils.h: prototypes for utils.c */ /* JMJ */
/* See the file COPYING for copying conditions */

char *quotation_marks(int depth, int type);
char *convert_extension(const char *old_name,const char *old_extension, const char *new_extension);
char *base_name(const char *s);
int strend(const char *s, const char *t);
