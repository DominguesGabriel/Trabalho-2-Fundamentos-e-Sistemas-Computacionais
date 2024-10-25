.data
mensagem_boas_vindas:      .string "Bem-vindo ao Blackjack!\n"
mensagem_opcao_jogo:       .string "Você deseja jogar? Digite S para sim e N para não: \n"
mensagem_recebeu:          .string "Você recebeu: "
mensagem_dealer_mostra:    .string "O dealer mostra: "
mensagem_opcao:            .string "O que você deseja fazer? (1 - Hit, 2 - Stand): \n"
mensagem_invalida:         .string "Opção inválida. Digite 1 para Hit ou 2 para Stand.\n"
mensagem_estouro:          .string "Você estourou! Dealer vence.\n"
mensagem_dealer_estouro:   .string "Dealer estourou! Você venceu.\n"
mensagem_dealer_vence:     .string "Dealer venceu com "
mensagem_jogador_vence:    .string "Você venceu com "
mensagem_empate:           .string "Empate!\n"
mensagem_jogar_novamente:  .string "Deseja jogar novamente? (S - Sim, N - Não): \n"
mensagem_opcao_invalida_jogo: .string "Opção inválida. Digite S para sim ou N para não.\n"
mensagem_fim_jogo:         .string "Obrigado por jogar!\n"

buffer:                    .space 10  # Buffer para armazenar a entrada do jogador
seed:                      .word 1    # Semente inicial para o gerador

.text
.globl _start

_start:
    # Exibe mensagem de boas-vindas e inicia o loop principal
    la a0, mensagem_boas_vindas
    li a7, 4               # syscall para imprimir string
    ecall

loop_principal:
    # Pergunta ao jogador se deseja jogar
    la a0, mensagem_opcao_jogo
    li a7, 4               # syscall para imprimir string
    ecall

leitura_jogo:
    # Lê a resposta do jogador (S ou N)
    la a0, buffer          # Carrega o endereço do buffer
    li a1, 10              # Tamanho máximo de caracteres a ler
    li a7, 8               # syscall para leitura de string
    ecall

    # Remove o caractere de nova linha ('\n') da entrada
    la t0, buffer          # Carrega a entrada lida em t0
    lb t1, 0(t0)           # Carrega o primeiro caractere
    lb t2, 1(t0)           # Carrega o segundo caractere (que deve ser '\n')

    li t3, '\n'            # Define '\n' para comparação
    beq t2, t3, entrada_valida # Se o segundo caractere for '\n', a entrada é válida

    j entrada_invalida_jogo # Renomeada para evitar duplicação

entrada_valida:
    li t2, 0               # Substitui o '\n' por '\0' (fim de string)
    sb t2, 1(t0)           # Grava o '\0' no lugar do '\n'

    # Verifica se o jogador digitou 'S' ou 'N'
    lb t2, 0(t0)           # Lê o caractere da entrada
    li t3, 'S'             # Carrega 'S' para comparar
    li t4, 'N'             # Carrega 'N' para comparar

    beq t2, t3, jogar      # Se digitou 'S', vai para o jogo
    beq t2, t4, fim_jogo   # Se digitou 'N', termina o jogo

    # Se a entrada for inválida, exibe mensagem de erro
entrada_invalida_jogo:
    la a0, mensagem_opcao_invalida_jogo
    li a7, 4               # syscall para imprimir string
    ecall
    j loop_principal       # Pergunta novamente

jogar:
    # Sorteio inicial de cartas para o jogador e dealer
    jal gerar_carta        # Sorteia primeira carta do jogador
    mv s1, a0              # Armazena carta do jogador em s1

    jal gerar_carta        # Sorteia segunda carta do jogador
    mv s2, a0              # Armazena segunda carta do jogador em s2

    jal gerar_carta        # Sorteia primeira carta do dealer
    mv s3, a0              # Armazena carta do dealer em s3

    jal gerar_carta        # Sorteia segunda carta do dealer
    mv s4, a0              # Armazena segunda carta do dealer em s4

    # Mostra as cartas do jogador e uma carta do dealer
    la a0, mensagem_recebeu
    li a7, 4
    ecall
    mv a0, s1              # Mostra a primeira carta do jogador
    li a7, 1               # syscall para imprimir inteiro
    ecall

    mv a0, s2              # Mostra a segunda carta do jogador
    li a7, 1               # syscall para imprimir inteiro
    ecall

    la a0, mensagem_dealer_mostra
    li a7, 4
    ecall
    mv a0, s3              # Mostra a primeira carta do dealer
    li a7, 1               # syscall para imprimir inteiro
    ecall

    # Calcula a pontuação do jogador
    jal calcular_pontuacao
    mv s5, a0              # Armazena a pontuação do jogador

turno_jogador:
    # Pede uma ação do jogador: Hit (1) ou Stand (2)
    la a0, mensagem_opcao
    li a7, 4
    ecall

    li a7, 5               # Leitura de número do jogador
    ecall
    li t4, 1
    bne a0, t4, verificar_stand
    # Jogador escolheu Hit, sorteia nova carta
    jal gerar_carta        # Sorteia mais uma carta
    mv t5, a0              # Armazena a nova carta recebida

    # Mostra a nova carta recebida
    la a0, mensagem_recebeu
    li a7, 4
    ecall
    mv a0, t5              # Mostra carta sorteada
    li a7, 1
    ecall

    # Atualiza a pontuação do jogador
    add s5, s5, t5         # Adiciona a nova carta à pontuação
    jal verificar_as        # Verifica se a contagem de As deve ser ajustada

    # Checa se o jogador estourou
    li t0, 21
    blt s5, t0, turno_jogador  # Se a pontuação é menor que 21, continua jogando

    # Jogador estourou
    la a0, mensagem_estouro
    li a7, 4
    ecall
    j jogar_novamente

verificar_stand:
    li t4, 2
    bne a0, t4, entrada_invalida_jogo  # Se não for Stand, checa se é inválida
    # Se for Stand, passa para o turno do dealer

turno_dealer:
    # Dealer revela suas cartas
    mv a0, s4              # Mostra segunda carta do dealer
    li a7, 1
    ecall

    # Simula o dealer tirando cartas se tiver menos de 17
    li t0, 17              # Dealer deve continuar até ter 17 ou mais
    blt s3, t0, dealer_hit  # Se total do dealer for menor que 17, compra mais uma

    # Fim do turno, verificação final

dealer_hit:
    jal gerar_carta        # Dealer tira mais uma carta
    mv s3, a0              # Atualiza carta do dealer

    j turno_dealer         # Volta para o turno do dealer

jogar_novamente:
    la a0, mensagem_jogar_novamente
    li a7, 4
    ecall
    j loop_principal       # Reinicia o loop principal

fim_jogo:
    la a0, mensagem_fim_jogo
    li a7, 4
    ecall
    li a7, 10              # Chamada de sistema para encerrar o programa
    ecall

# Função para gerar um número aleatório entre 0 e 12
gerar_carta:
    li a1, 12              # Limite superior (12)
    li a2, 0               # Valor mínimo (0)
    jal random             # Chama função para gerar número aleatório
    add a0, a0, a2         # Ajusta para garantir que seja entre 0 e 12
    addi a0, a0, 1         # Adiciona 1 ao número gerado (para garantir que seja entre 1 e 13)
    ret

# Função para verificar e ajustar a contagem de As
verificar_as:
    # Se a pontuação do jogador ultrapassar 21, e se houver As, ajusta o valor
    li t0, 11              # Valor do As como 11
    li t1, 1               # Valor do As como 1
    li t2, 21              # Limite de estourar
    blt s5, t2, fim_verificacao  # Se a pontuação é menor que 21, não faz nada

    # Ajustar se houver um As e a pontuação estourar
    sub s5, s5, t0         # Tenta ajustar 11 para 1
    add s5, s5, t1         # Adiciona 1 ao total
fim_verificacao:
    ret

# Função para calcular a pontuação do jogador
calcular_pontuacao:
    # Calcula a pontuação considerando valores de 10 para Valetes, Damas e Reis
    mv t0, s1              # Carrega a primeira carta
    mv t1, s2              # Carrega a segunda carta

    # Calcula a pontuação
    li t2, 10
    bge t0, t2, ajusta_valor1
    j continua1
ajusta_valor1:
    li t0, 10
continua1:
li t6,10
    bge t1, t6, ajusta_valor2
    j continua2
ajusta_valor2:
    li t1, 10
continua2:
    add a0, t0, t1         # Totaliza a pontuação
    ret

# Função para gerar um número aleatório
random:
    la t3, seed            # Carrega o endereço da semente
    lw t0, 0(t3)           # Carrega a semente no registrador t0

    # Fórmula do gerador de números aleatórios (usando deslocamentos)
    slli t0, t0, 1         # Desloca t0 para a esquerda (multiplica por 2)
    addi t0, t0, 1         # Adiciona 1 para a semente

    sw t0, 0(t3)           # Atualiza a semente
    andi t0, t0, 0x0F      # Garante que o resultado esteja entre 0 e 15 (0 a 12)
    mv a0, t0              # Move o resultado para a0
    ret