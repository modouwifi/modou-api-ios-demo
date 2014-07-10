/* Copyright 1998 by the Massachusetts Institute of Technology.
 *
 *
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any purpose and without
 * fee is hereby granted, provided that the above copyright
 * notice appear in all copies and that both that copyright
 * notice and this permission notice appear in supporting
 * documentation, and that the name of M.I.T. not be used in
 * advertising or publicity pertaining to distribution of the
 * software without specific, written prior permission.
 * M.I.T. makes no representations about the suitability of
 * this software for any purpose.  It is provided "as is"
 * without express or implied warranty.
 */

//#include "ares_setup.h"
#include <resolv.h>
#if !defined(WIN32) || defined(WATT32)
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#endif
#ifdef HAVE_STRINGS_H
#include <strings.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <arpa/nameser.h>
#include "include/ares.h"
#include "include/ares_dns.h"
//const char *ares_inet_ntop(int af, const void *src, char *dst, size_t size);
#define ares_inet_ntop(w,x,y,z) inet_ntop(w,x,y,z)
//int ares_inet_pton(int af, const char *src, void *dst);
#define ares_inet_pton(x,y,z) inet_pton(x,y,z)
//#include "inet_ntop.h"
//#include "inet_net_pton.h"
//#include "ares_getopt.h"
//#include "ares_ipv6.h"
//#include "ares_nowarn.h"

//#ifndef !HAVE_STRDUP
//#  include "ares_strdup.h"
//#  define strdup(ptr) ares_strdup(ptr)
//#endif

//#ifndef HAVE_STRCASECMP
//#  include "ares_strcasecmp.h"
//#  define strcasecmp(p1,p2) ares_strcasecmp(p1,p2)
//#endif

//#ifndef HAVE_STRNCASECMP
//#  include "ares_strcasecmp.h"
//#  define strncasecmp(p1,p2,n) ares_strncasecmp(p1,p2,n)
//#endif

static void callback(void *arg, int status, int timeouts, struct hostent *host);
//static void callback_ns(void *arg, int status, int timeouts, unsigned char *abuf, int alen)
//{
//    struct hostent *host = NULL;
//    ares_parse_ns_reply(abuf, alen, &host);
//    // your result now in "host" variable
//}

int ahost(char *ipaddr)
{
  ares_channel channel;
  int status, nfds;
  fd_set read_fds, write_fds;
  struct timeval *tvp, tv;
  struct in_addr addr4;
  

#ifdef USE_WINSOCK
  WORD wVersionRequested = MAKEWORD(USE_WINSOCK,USE_WINSOCK);
  WSADATA wsaData;
  WSAStartup(wVersionRequested, &wsaData);
#endif

  status = ares_library_init(ARES_LIB_INIT_ALL);
  if (status != ARES_SUCCESS)
    {
      fprintf(stderr, "ares_library_init: %s\n", ares_strerror(status));
      return 1;
    }


  
    


  status = ares_init(&channel);
  if (status != ARES_SUCCESS)
    {
      fprintf(stderr, "ares_init: %s\n", ares_strerror(status));
      return 1;
    }

    struct ares_addr_node *servers;
    servers = malloc(sizeof(struct ares_addr_node));
    //memset(servers, 0, sizeof(servers));
    servers->family=AF_INET;
    struct in_addr       *saddr4;
    saddr4 = malloc(sizeof(struct in_addr));
    saddr4->s_addr= inet_addr(ipaddr);
    
    servers->addr.addr4 = *saddr4;
    
    ares_set_servers(channel,servers);
  /* Initiate the queries, one per command-line argument. */
  
    if (ares_inet_pton(AF_INET, ipaddr, &addr4) == 1)
    {
        ares_gethostbyaddr(channel, &addr4, sizeof(addr4), AF_INET, callback,
                           ipaddr);
    }else
    {
        //printf("123\n");
        ares_gethostbyname(channel, ipaddr, AF_INET, callback, ipaddr);
    }
  /* Wait for all queries to complete. */
  for (;;)
    {
      FD_ZERO(&read_fds);
      FD_ZERO(&write_fds);
      nfds = ares_fds(channel, &read_fds, &write_fds);
      if (nfds == 0)
        break;
      tvp = ares_timeout(channel, NULL, &tv);
      select(nfds, &read_fds, &write_fds, NULL, tvp);
      ares_process(channel, &read_fds, &write_fds);
    }

  ares_destroy(channel);

  ares_library_cleanup();

#ifdef USE_WINSOCK
  WSACleanup();
#endif
 
  return 0;
}



static void callback(void *arg, int status, int timeouts, struct hostent *host)
{
  char **p;

  (void)timeouts;

  if (status != ARES_SUCCESS)
    {
      fprintf(stderr, "%s: %s\n", (char *) arg, ares_strerror(status));
      return;
    }

  for (p = host->h_addr_list; *p; p++)
    {
      char addr_buf[46] = "??";

      ares_inet_ntop(host->h_addrtype, *p, addr_buf, sizeof(addr_buf));
      printf("%-32s\t%s", host->h_name, addr_buf);
#if 0
      if (host->h_aliases[0])
        {
           int i;

           printf (", Aliases: ");
           for (i = 0; host->h_aliases[i]; i++)
               printf("%s ", host->h_aliases[i]);
        }
#endif
      puts("");
    }
}

//static void usage(void)
//{
//  fprintf(stderr, "usage: ahost [-t {a|aaaa}] {host|addr} ...\n");
//  exit(1);
//}
