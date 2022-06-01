#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <linux/if_ether.h>
#include <arpa/inet.h>
#include <string.h>

int main(int argc, char **argv) {
  int sock, n;
  char buffer[2048];
  unsigned char *iphead, *ethhead;

  if ( (sock=socket(PF_PACKET, SOCK_RAW,
                    htons(ETH_P_IP)))<0) {
    perror("socket");
    exit(1);
  }

  //setsockopt(SOL_PACKET, PACKET_ADD_MEMBERSHIP, PACKET_MR_PROMISC);

	struct ifreq ifr;
	strncpy((char*)ifr.ifr_name, interface, IF_NAMESIZE);
	if(ioctl(sock, SIOCGIFINDEX, &ifr)<0) fail(2);

	struct packet_mreq mr;
	memset(&mr, 0, sizeof(mr));
	mr.mr_ifindex = ifr.ifr_ifindex;
	mr.mr_type = PACKET_MR_PROMISC;
	if(setsockopt(sock, SOL_PACKET, PACKET_ADD_MEMBERSHIP, &mr, sizeof(mr)) < 0) fail(2)

  while (1) {
    printf("----------\n");
    n = recvfrom(sock,buffer,2048,0,NULL,NULL);
    printf("%d bytes read\n",n);

    /* Check to see if the packet contains at least
     * complete Ethernet (14), IP (20) and TCP/UDP
     * (8) headers.
     */
    if (n<42) {
      perror("recvfrom():");
      printf("Incomplete packet (errno is %d)\n",
             errno);
      close(sock);
      exit(0);
    }

    ethhead = buffer;
    printf("Source MAC address: "
           "%02x:%02x:%02x:%02x:%02x:%02x\n",
           ethhead[0],ethhead[1],ethhead[2],
           ethhead[3],ethhead[4],ethhead[5]);
    printf("Destination MAC address: "
           "%02x:%02x:%02x:%02x:%02x:%02x\n",
           ethhead[6],ethhead[7],ethhead[8],
           ethhead[9],ethhead[10],ethhead[11]);

    iphead = buffer+14; /* Skip Ethernet header */
    if (*iphead==0x45) { /* Double check for IPv4
                          * and no options present */
      printf("Source host %d.%d.%d.%d\n",
             iphead[12],iphead[13],
             iphead[14],iphead[15]);
      printf("Dest host %d.%d.%d.%d\n",
             iphead[16],iphead[17],
             iphead[18],iphead[19]);
      printf("Source,Dest ports %d,%d\n",
             (iphead[20]<<8)+iphead[21],
             (iphead[22]<<8)+iphead[23]);
      printf("Layer-4 protocol %d\n",iphead[9]);
    }
  }

}

