#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <dirent.h>     /* Defines DT_* constants */
#include <stdlib.h>
#include <sys/stat.h>

//int checknpheader64(char *data, unsigned long data_size);

int recursive(char *path);

int main(int ac, char **av)
{
	int a = DT_REG;
	char buff[1000];
	int ret;

	if (ac != 2)
		return (0);
	strcpy(buff, av[1]);
//	int fd = open("a.out", O_RDONLY);
//	size_t len = lseek(fd, 0, SEEK_END);
//	char *a = mmap(0, len, PROT_READ, MAP_SHARED, fd, 0);
	ret = recursive(buff);
	printf("%d\n", ret);
//	printf("%d\n", checknpheader64(a, len));
	return (0);
}