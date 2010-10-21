/* utils.c: utility functions for html2texi */ /* JMJ */
/* See the file COPYING for copying conditions */

#include <config.h>
#include <string.h>
#include <stdio.h>
#include <utils.h>

/* quotation_marks:
   return an appropriate type of quotation marks based on
   depth: if 1 then double, if >1 then single quotes
   type: if 0 then return open, if 1 then return close quotes

   The caller should insure that depth and type have the proper values.
*/

char *
quotation_marks(int depth, int type)
{
  if (depth >=2) return (!type)?"`":"'";
  else return (!type)?"``":"''";
}

/* convert_extension:
   change the extension of old_name to
   new_extension if old_name ends with any extension in
   old_extension. otherwise, append new_extension to old_name.
   old_name: the name to be changed
   old_extension: extension to be replaced
   new_extension: the new extension
*/

char *
convert_extension(const char *old_name,const char *old_extension,const char *new_extension)
{
  char *new_name;

  if (strend(old_name,old_extension)) {
    new_name=strndup(old_name,strlen(old_name)-strlen(old_extension));
    new_name=strcat(new_name,new_extension);
  }
  else {
    new_name=strdup(old_name);
    new_name=strcat(new_name,new_extension);
  }
  return new_name;
}

/* base_name:
   return a copy of the basename of s, as if s were a filename.
   would be more portable if the '/' werent hardcoded.
*/

char *
base_name(const char *s)
{
  char *ptr;

  return (ptr=strrchr(s,'/'))?strdup(++ptr):strdup(s);
}

/* strend:
   return non-zero if a string s ends with a substring t, 0 otherwise.
*/

int strend(const char *s, const char *t)
{

  return !strcmp(s+strlen(s)-strlen(t),t);
}

/*
Local Variables:
mode: c
compile-command: "make"
End:
*/
