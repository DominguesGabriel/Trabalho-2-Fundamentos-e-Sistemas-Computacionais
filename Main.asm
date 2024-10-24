.data
mensagem_boas_vindas:  .string "Bem-vindo ao Blackjack!\n"
mensagem_opcao_jogo:   .string "Voce deseja jogar? Digite S para sim e N para nao\n"
mensagem_recebeu:      .string "Voce recebeu: "
mensagem_dealer_mostra: .string "O dealer mostra: "
mensagem_opcao:        .string "O que voce deseja fazer? (1 - Hit, 2 - Stand): \n"
mensagem_invalida:     .string "Opcao invalida. Digite 1 para Hit ou 2 para Stand.\n"
mensagem_estouro:      .string "Voce estourou! Dealer vence.\n"
mensagem_dealer_estouro:.string "Dealer estourou! Voce venceu.\n"
mensagem_dealer_vence: .string "Dealer venceu com "
mensagem_jogador_vence:.string "Voce venceu com "
mensagem_empate:       .string "Empate!\n"
mensagem_jogar_novamente: .string "Deseja jogar novamente? (1 - Sim, 2 - Nao): \n"
mensagem_digite_valido:.string "Digite um valor valido\n"
mensagem_fim_jogo:     .string "Obrigado por jogar!\n"

buffer: .space 1           # Buffer para armazenar a entrada do jogador (1 byte)
seed:   .word 1            # Semente inicial para o gerador

    .text
    .globl _start

_start:
    # Inicializa valores e variáveis
    li a5, 1               # Flag para continuar jogando (1 = sim, 0 = não)

loop_principal:
    beqz a5, fim_jogo       # Se a flag for 0, encerra o jogo

    # Exibe mensagem de boas-vindas
    la a0, mensagem_boas_vindas
    li a7, 4               # syscall para imprimir string
    ecall

    # Pergunta ao jogador se deseja jogar
    la a0, mensagem_opcao_jogo
    li a7, 4               # syscall para imprimir string
    ecall

    # Lê resposta do jogador (S ou N)
    la a0, buffer          # Carrega o endereço do buffer
    li a7, 8               # syscall para leitura de string (até 1 char)
    ecall
    lb t0, 0(a0)           # Carrega o primeiro byte do buffer para t0
    li t1, 'n'             # Carrega 'n' em t1 para comparação
    beq t0, t1, fim_jogo   # Se o jogador digitar 'n', sai do loop

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
    mv s1, a0              # Atualiza carta recebida

    # Mostra a nova carta recebida
    la a0, mensagem_recebeu
    li a7, 4
    ecall
    mv a0, s1              # Mostra carta sorteada
    li a7, 1
    ecall

    j turno_jogador        # Continua pedindo nova ação do jogador

verificar_stand:
    li t4, 2
    bne a0, t4, entrada_invalida  # Se não for Stand, checa se é inválida
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

entrada_invalida:
    # Mensagem de erro para opção inválida
    la a0, mensagem_invalida
    li a7, 4
    ecall
    j turno_jogador        # Volta para o turno do jogador

jogar_novamente:
    la a0, mensagem_jogar_novamente
    li a7, 4
    ecall
    li a7, 5               # Lê opção do jogador
    ecall
    li t4, 1
    bne a0, t4, fim_jogo   # Se escolher não jogar (2), fim do jogo
    j loop_principal       # Reinicia o loop

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

# Função para gerar um número aleatório
random:
    la t3, seed            # Carrega o endereço da semente
    lw t0, 0(t3)           # Carrega a semente no registrador t0
    li t1, 1103515245      # Constante para multiplicação
    li t2, 12345           # Constante para adição
    mul t0, t0, t1         # t0 = t0 * 1103515245
    add t0, t0, t2         # t0 = t0 + 12345
    andi t0, t0, 0xFFFFFFFF # Garante que o número esteja dentro do limite
    sw t0, 0(t3)           # Armazena a nova semente no endereço da semente
    srli t0, t0, 1         # Shift right para obter o número aleatório
    ret