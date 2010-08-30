#line 50945 "configure"
#include "confdefs.h"

    
#if defined(__GNUC__) && __GNUC__ >= 4
# define PHP_IMAP_EXPORT __attribute__ ((visibility("default")))
#else
# define PHP_IMAP_EXPORT
#endif

    PHP_IMAP_EXPORT void mm_log(void){}
    PHP_IMAP_EXPORT void mm_dlog(void){}
    PHP_IMAP_EXPORT void mm_flags(void){}
    PHP_IMAP_EXPORT void mm_fatal(void){}
    PHP_IMAP_EXPORT void mm_critical(void){}
    PHP_IMAP_EXPORT void mm_nocritical(void){}
    PHP_IMAP_EXPORT void mm_notify(void){}
    PHP_IMAP_EXPORT void mm_login(void){}
    PHP_IMAP_EXPORT void mm_diskerror(void){}
    PHP_IMAP_EXPORT void mm_status(void){}
    PHP_IMAP_EXPORT void mm_lsub(void){}
    PHP_IMAP_EXPORT void mm_list(void){}
    PHP_IMAP_EXPORT void mm_exists(void){}
    PHP_IMAP_EXPORT void mm_searched(void){}
    PHP_IMAP_EXPORT void mm_expunged(void){}
  
    char mail_newbody();
int main() {
      mail_newbody();
      return 0;
    }
  
