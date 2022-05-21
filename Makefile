# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: t <t@student.42.fr>                        +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2018/10/03 11:06:26 by yalabidi          #+#    #+#              #
#    Updated: 2022/05/20 21:27:45 by t                ###   ########.fr        #
#                                                                              #
# **************************************************************************** #


BLUE=\033[0;38;5;123m
LIGHT_PINK = \033[0;38;5;200m
PINK = \033[0;38;5;198m
DARK_BLUE = \033[1;38;5;110m
GREEN = \033[1;32;111m
LIGHT_GREEN = \033[1;38;5;121m
LIGHT_RED = \033[0;38;5;110m
FLASH_GREEN = \033[33;32m
WHITE_BOLD = \033[37m

# nom de l'executable
NAME = famine

#sources path
SRC_ASM_PATH= srcs

#objects path
OBJ_ASM_PATH= .objs

#includes
INC_PATH_ASM= -i srcs/ -i includes

NAME_SRC_ASM=main.s

SRC_LINK=append.s check_pheader.s ft_strcpy.s ft_strlen.s injection.s main.s recursive.s get_processus_actif.s putnbr.s


NAME_SRC_LINK = $(addprefix $(SRC_ASM_PATH)/,$(SRC_LINK))


NAME_SRC_LEN	= $(shell echo -n $(NAME_SRC) $(NAME_SRC_ASM) | wc -w)
I				= 0


OBJ_NAME_ASM	= $(NAME_SRC_ASM:.s=.o)

OBJS = $(addprefix $(OBJ_ASM_PATH)/,$(OBJ_NAME_ASM))

CC			= clang
NASM		= nasm -f elf64 $(INC_PATH_ASM)
CFLAGS		= -Wall -Werror -Wextra

all: $(NAME)

$(NAME) : $(OBJS)
	@$(CC) $^ -o $@
	@echo "	\033[2K\r$(DARK_BLUE)$(NAME):\t\t$(GREEN)loaded\033[0m"


$(OBJ_ASM_PATH)/%.o: $(SRC_ASM_PATH)/%.s  $(NAME_SRC_LINK) includes/include.s includes/data.s
	@mkdir $(OBJ_ASM_PATH) 2> /dev/null || true
	@$(NASM) $< -o $@
	@$(eval I=$(shell echo $$(($(I)+1))))
	@printf "\033[2K\r${G}$(DARK_BLUE)>>\t\t$(I)/$(shell echo $(NAME_SRC_LEN)) ${N}$(BLUE)$<\033[36m \033[0m"



clean:
ifeq ("$(wildcard $(OBJ_ASM_PATH))", "")
else
	@rm -f $(OBJS)
	@rmdir $(OBJ_ASM_PATH) 2> /dev/null || true
	@printf "\033[2K\r$(DARK_BLUE)$(NAME) objects:\t$(LIGHT_PINK)removing\033[36m \033[0m\n"
endif


fclean: clean
	@rm -f woody
ifeq ("$(wildcard $(NAME))", "")
else
	@rm -f $(NAME)
	@printf "\033[2K\r$(DARK_BLUE)$(NAME):\t\t$(PINK)removing\033[36m \033[0m\n"
endif

re: fclean all

test: all
	@sh .test.sh
	

.PHONY: all re clean fclean lib test silent
