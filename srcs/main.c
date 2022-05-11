#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

int checknpheader64(char *data, unsigned long data_size);

int main()
{
	int fd = open("a.out", O_RDONLY);
	size_t len = lseek(fd, 0, SEEK_END);
	char *a = mmap(0, len, PROT_READ, MAP_SHARED, fd, 0);

	printf("%d\n", checknpheader64(a, len));
	return (0);
}