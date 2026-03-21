class ShowTransactionSelectorTool < RubyLLM::Tool
  description "Apresenta ao usuário opções interativas no chat para adicionar um Gasto, Receita ou Investimento. Use APENAS quando o usuário quiser adicionar um lançamento mas não deu os detalhes completos. IMPORTANTE: Ao usar esta ferramenta, sua resposta final para o usuário DEVE conter OBRIGATORIAMENTE o texto [WIZARD:TRANSACTION_SELECTOR]"

  params do
    string :transaction_type, description: "O tipo de transação ('expense', 'income', 'investment')"
  end

  def execute(transaction_type: "unknown")
    "Ferramenta executada com sucesso. A interface do usuário aguarda o sinal. Você DEVE e SÓ PODE responder com o seguinte texto exato: [WIZARD:TRANSACTION_SELECTOR]"
  end
end
