# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: max <max@student.42.fr>                    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2018/10/03 11:06:26 by yalabidi          #+#    #+#              #
#    Updated: 2022/05/12 08:22:17 by max              ###   ########.fr        #
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
SRC_PATH= srcs
SRC_ASM_PATH= srcs

#objects path
OBJ_PATH= objs
OBJ_ASM_PATH= objs

#includes
INC_PATH_ASM= -i srcs/ -i includes
INC_PATH=

HEADER=

NAME_SRC=

NAME_SRC_ASM=main.s

SRC_LINK=append.s check_pheader.s data.s ft_strcpy.s ft_strlen.s injection.s main.s putnbr.s recursive.s


NAME_SRC_LINK = $(addprefix $(SRC_ASM_PATH)/,$(SRC_LINK))


NAME_SRC_LEN	= $(shell echo -n $(NAME_SRC) $(NAME_SRC_ASM) | wc -w)
I				= 0

OBJ_NAME		= $(NAME_SRC:.c=.o)
OBJ_NAME_ASM	= $(NAME_SRC_ASM:.s=.o)

OBJS = $(addprefix $(OBJ_PATH)/,$(OBJ_NAME)) $(addprefix $(OBJ_ASM_PATH)/,$(OBJ_NAME_ASM))

CC			= clang
NASM		= nasm -f elf64 $(INC_PATH_ASM)
CFLAGS		= -Wall -Werror -Wextra

all: $(NAME)

$(NAME) : $(OBJS) $(LIBFT.A)
	@$(CC) $^ -o $@
	@echo "	\033[2K\r$(DARK_BLUE)$(NAME):\t\t$(GREEN)loaded\033[0m"

$(OBJ_PATH)/%.o: $(SRC_PATH)/%.c
	@mkdir $(OBJ_PATH) 2> /dev/null || true
	@$(CC) -I $(INC_PATH) -I $(LIBFT_INC) -c $< -o $@
	@$(eval I=$(shell echo $$(($(I)+1))))
	@printf "\033[2K\r${G}$(DARK_BLUE)>>\t\t$(I)/$(shell echo $(NAME_SRC_LEN)) ${N}$(BLUE)$<\033[36m \033[0m"


$(OBJ_ASM_PATH)/%.o: $(SRC_ASM_PATH)/%.s $(NAME_SRC_LINK) includes/include.s
	@mkdir $(OBJ_ASM_PATH) 2> /dev/null || true
	@$(NASM) $< -o $@
	@$(eval I=$(shell echo $$(($(I)+1))))
	@printf "\033[2K\r${G}$(DARK_BLUE)>>\t\t$(I)/$(shell echo $(NAME_SRC_LEN)) ${N}$(BLUE)$<\033[36m \033[0m"



clean:
ifeq ("$(wildcard $(OBJ_PATH))", "")
else
	@rm -f $(OBJS)
	@rmdir $(OBJ_PATH) 2> /dev/null || true
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

	

.PHONY: all re clean fclean lib test silent
