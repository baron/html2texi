%{
  /* html2texi.l: a scanner which turns html input into texinfo */ /* JMJ */
  /* See the file COPYING for copying conditions */

#include <config.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>
#include <utils.h>
#include <html2texi.h>

  char *program_name;

%}

%option caseless yylineno stack
%x TAG END_TAG COMMENT  META LINK BASE ANCHOR IMG

unquoted_value [-[:alnum:].]*
single_quoted_value '[^']*'
double_quoted_value \"[^"]*\"
name_is_value [[:alpha:]]+=({unquoted_value}|{single_quoted_value}|{double_quoted_value})?
name_value_pairs ([[:space:]]*{name_is_value}[[:space:]]*)+

edible html|sub|sup
phrase em|strong|dfn|code|samp|kbd|var|cite|acronym
font_style (i|b|tt|u)[[:space:]]*

%%

%{
	int in_quotation=0, in_dt=0, a_close_brace=0;
	int in_head=0, at_html=0;
	char *a_name=NULL, *a_href=NULL, *img_src=NULL;

%}

<*>\n*"<" yy_push_state(TAG);
<*>\n*"</" yy_push_state(END_TAG);

<TAG>! yy_push_state(COMMENT);
<COMMENT>[^>\n]* fprintf(yyout,"@c "); ECHO;
<COMMENT>\n+ fprintf(yyout,"\n");
<COMMENT>">"\n* {
	fprintf(yyout,"\n");
	yy_pop_state(); yy_pop_state();
	/* pop once for current state and twice for TAG */
	}

<TAG>head in_head=1;
<END_TAG>head {
	if (at_html) fprintf(yyout,"\n@end html\n");
	at_html=in_head=0;
	}

<TAG>title fprintf(yyout,"@settitle ");
<END_TAG>title fprintf(yyout,"\n");

<TAG>meta {
	if (!at_html) {fprintf(yyout,"\n@html\n"); at_html=1;}
	fprintf(yyout,"<meta "); yy_push_state(META);
	}
<META>[^>\n]* ECHO;
<META>\n+ fprintf(yyout,"\n");
<META>">" {
	ECHO;
	if (!in_head) {fprintf(yyout,"\n@end html\n"); at_html=0;}
	yy_pop_state(); yy_pop_state();
	/* pop once for current state and twice for TAG */
	}

<TAG>link {
	if (!at_html) {fprintf(yyout,"\n@html\n"); at_html=1;}
	fprintf(yyout,"<link "); yy_push_state(LINK);
	}
<LINK>[^>\n]* ECHO;
<LINK>\n+ fprintf(yyout,"\n");
<LINK>">" {
	ECHO;
	if (!in_head) {fprintf(yyout,"\n@end html\n"); at_html=0;}
	yy_pop_state(); yy_pop_state();
	/* pop once for current state and twice for TAG */
	}
<TAG>base {
	if (!at_html) {fprintf(yyout,"\n@html\n"); at_html=1;}
	fprintf(yyout,"<base "); yy_push_state(BASE);
	}
<BASE>[^>\n]* ECHO;
<BASE>\n+ fprintf(yyout,"\n");
<BASE>">" {
	ECHO;
	if (!in_head) {fprintf(yyout,"\n@end html\n"); at_html=0;}
	yy_pop_state(); yy_pop_state();
	/* pop once for current state and twice for TAG */
	}

<TAG,END_TAG>div fprintf(yyout,"\n");

<TAG>h1 fprintf(yyout,"\n@chapter ");
<END_TAG>h1 fprintf(yyout,"\n");

<TAG>h2 fprintf(yyout,"\n@section "); 
<END_TAG>h2 fprintf(yyout,"\n");

<TAG>h3 fprintf(yyout,"\n@subsection "); 
<END_TAG>h3 fprintf(yyout,"\n");

<TAG>h[456] fprintf(yyout,"\n@subsubsection "); 
<END_TAG>h[456] fprintf(yyout,"\n");

<TAG>a yy_push_state(ANCHOR);
<ANCHOR>name={double_quoted_value} a_name=strndup(yytext+6,strlen(yytext)-7);
<ANCHOR>href={double_quoted_value} {
	a_close_brace=1;
	a_href=strndup(yytext+6,strlen(yytext)-7);
	}
<ANCHOR>">"\n* {
	if (a_name) {
		fprintf(yyout,"@anchor{%s}",a_name);
		free(a_name);
		a_name=NULL;
	}
	if (a_href) {
		fprintf(yyout,"@uref{%s,",a_href);
		free(a_href);
		a_href=NULL;
}
	yy_pop_state(); yy_pop_state();
}
<ANCHOR>. /* eat unrecognized anchor attributes */
<END_TAG>a {
	if (a_close_brace) fprintf(yyout,"}");
	a_close_brace=0;
	}

<TAG>{phrase} fprintf (yyout,"@%s{",yytext);
<END_TAG>{phrase} fprintf(yyout,"}");

<TAG>blockquote fprintf (yyout,"\n@quotation\n");
<END_TAG>blockquote fprintf (yyout,"\n@end quotation\n"); 

<TAG>q fprintf(yyout,"%s",quotation_marks(++in_quotation,0));
<END_TAG>q fprintf(yyout,"%s",quotation_marks(in_quotation--,1));

<TAG>p fprintf(yyout,"\n\n");
<END_TAG>p /* eat */

<TAG>br fprintf(yyout,"@*");

<TAG>pre fprintf(yyout,"\n@format\n");
<END_TAG>pre fprintf(yyout,"\n@end format\n");

<TAG>ol fprintf(yyout,"\n@enumerate\n");
<END_TAG>ol fprintf(yyout,"\n@end enumerate\n");

<TAG>ul fprintf(yyout,"\n@itemize\n");
<END_TAG>ul fprintf(yyout,"\n@end itemize\n");

<TAG>li fprintf(yyout,"@item ");
<END_TAG>li /* eat */

<TAG>dl fprintf(yyout,"\n@table\n");
<END_TAG>dl fprintf(yyout,"\n@end table\n"); in_dt=0;

<TAG>dt fprintf(yyout,"%s ", (!in_dt)?"@item":"@itemx"); in_dt=1;
<END_TAG>dt in_dt=0;

<TAG>dd in_dt=0; fprintf(yyout,"\n");
<END_TAG>dd /* eat */

<TAG>img fprintf(yyout,"@image{"); yy_push_state(IMG);
<IMG>src=({single_quoted_value}|{double_quoted_value}) {
	fprintf(yyout,"%s",strndup(yytext+5,strlen(yytext)-6));
	free(img_src);
	}
<IMG>src={unquoted_value} {
	fprintf(yyout,"%s",strndup(yytext+4,strlen(yytext)-5));
	free(img_src);
	}
<IMG>">" fprintf(yyout,"}"); yy_pop_state(); yy_pop_state();
<IMG>. /* eat other name=value attributes */

<TAG>{font_style}/">" fprintf(yyout,"@%s{",yytext);
<END_TAG>{font_style}/">" fprintf(yyout,"}");

<TAG>hr fprintf(yyout,"\n");

<TAG>{name_value_pairs}*">"\n* yy_pop_state();
<END_TAG>">"\n+ fprintf(yyout,"\n");  yy_pop_state();
<END_TAG>">" yy_pop_state();

<TAG,END_TAG>{edible} /* eat */
<TAG,END_TAG>. /* eat unrecognized tags */

. ECHO;  
<*>\n+ fprintf(yyout,"\n");

%%

int
main (int argc, char **argv)
{
	int i;
	char *name_yyout;
	char *input_suffix, *output_suffix;

	program_name=argv[0];
	input_suffix=".html";
	output_suffix=".texi";

	if (argc==1) {
		yyin = stdin;
		yylex();
		exit(EXIT_SUCCESS);
	} /* if no filename arguments */
	for (i=1; i<argc; i++) {
		if (strcmp(argv[i],"-")) {
			yyin=fopen(argv[i],"r");
		} /* argv[i] is not "-" */
		else yyin=stdin;
		if (!yyin) {
			fprintf(stderr,"%s: %s: %s\n",program_name,argv[i],strerror(errno));
			exit(errno);
		} /* !yyin */
		yylex();
		fclose(yyin);
	} /* for i indexes argv */

	return 0;
} /* main */

/*
Local Variables:
mode: c
compile-command: "make"
End:
*/
