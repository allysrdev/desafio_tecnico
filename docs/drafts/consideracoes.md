# Considerações e relato de experiência de desenvolvimento

## Primeiras impressões

Este foi o meu primeiro contato com a stack Elixir/OTP e LiveView. Com o background em Javascript, Typescript, React e Angular. Mesmo com a notável diferença de sintaxe, a primeira impressão é de difuculdade média para a compreensão.

- Funções:

Em Typescript funções são dadas pela forma:

```typescript
function Exemplo() {
  console.log("Hello World");
}
```

Já em elixir:

```elixir
def exemplo() do

end
```

Como também tive contato com python no início da minha carreira, o uso do def para definir funções não é uma surpresa para mim. E o do, end, são bastante auto explicativos, lembrando a estrutura de loop do {} while (condição). Acredito que a curva de aprendizado ao transicionar para esta stack não seria tão grande, o que me deixa interessado em expandir meus conhecimentos na ferramaneta.

- Estrutura de pasta:

A estrutura de pasta gerada inicialmente não me pareceu complexa, e sim objetiva. Nota-se uma divisão clara entre domínio e web dentro da pasta lib, o que também pode acontecer no React (tipo `services/`), mas o React tem uma estrutura mais flexível. A organização em módulos reforça o princípio de isolamento e responsabilidade única.

- Componentização:
  Geralmente, em React, utilizamos `components/`e modularizamos todos os componentes dentro da pasta components. Já no projeto, criei um arquivo design_system que contém todos os componentes centralizados.

## Otimização de tempo na transição de Stack

Utilizei IA como ferramenta de apoio para acelerar a adaptação inicial à stack, principalmente em configurações e entendimento de padrões idiomáticos, mantendo o foco na compreensão dos conceitos e decisões arquiteturais.

## Design System

Apesar do costume com Tailwind, todos os componentes do design system fazem uso de CSS puro com utilização de variáveis, por recomendação do agente, levando em consideração que gera um bundle menor e existe um controle melhor sobre os detalhes visuais. Transicionar entre Tailwind e CSS é algo corriqueiro, visto que também trabalho com CSS em projetos Angular.

- Revisão de acessibilidade:

Com o copiloto, escaneei por oportunidades melhoria de acessibilidade nos componentes do design system e no design system em si, tendo com output:

1. o uso de @moduledoc e @doc para documentação de uso e composição dos componentes, simulando uma boa troca com o time de desenvolvimento, possibilitando outros desenvolvedores entenderem o funcionamento dos componentes;
2. O uso do atributo `role="role"` sempre que possível para indicar a função do componente para leitores de acessibilidade;
3. Adição do atributo `aria-label="label` para informar para leitores de acessibilidade o que está sendo dito naquele componente;
4. Uso de `aria-live` para anunciar mudanças críticas.
5. Uso de tags semânticas como o `<header></header>` boa prática em HTML.

- Próximos passos:
  O ideal como próximo passo seria verificar as condições de acessibilidade com as cores a partir do CSS.

## A questão da reatividade: O que eu comprendi

A partir do mock criado e do simulador, criado com GenServer, foi possível simular as mudanças de estado, onde essas mudanças são publicadas utilizando PubSub com o identificador de "machine:updates". Esse mesmo identificador é utilizado pela view para se inscrever neste "canal" e "escutar" as atualizações.

Ao escutar as atualizações, é executada a lógica de atualização da interface e highlighting temporário da máquina que sofreu a atualização.

Diferente do React, onde a reatividade depende de estado local e ciclos de renderização no cliente, no LiveView a reatividade é orientada a eventos no servidor, reduzindo a complexidade de sincronização entre cliente e backend.

## Sobre os paralelos traçados com React/Typescript

1. Struct -> Contrato de dados (@type t), ou Interface em Typescript (interface Interface {})
2. setInterval, useState, useEffect, todos facilmente abstraidos pela stack.

   | Conceito React/JS              | Equivalente Elixir                                 |
   | ------------------------------ | -------------------------------------------------- |
   | `setInterval(fn, 2000)`        | `Process.send_after(self(), :tick, 2000)`          |
   | `useState(machines)`           | Estado interno do GenServer (`machines` no `init`) |
   | `setState(newMachines)`        | `{:noreply, updated_machines}`                     |
   | `useEffect` cleanup            | Não necessário — processo morre e para sozinho     |
   | `export function listMachines` | `def list_machines` (API pública)                  |

3. Props > attr
4. children > slot :inner_block
5. HEEx e TSX similares:

   ```heex
   <%!-- HEEx --%>
   <.card class="wc-machine-card">
   <h3>Conteúdo aqui</h3>
   </.card>
   ```

   ```jsx
   <%!-- JSX equivalente --%>
   <Card className="wc-machine-card">

     <h3>Conteúdo aqui</h3>
   </Card>
   ```

6. Gerenciando estado: No React, o estado fica no cliente, geralmente utilizando ferramentas como Context API, Zustand ou Redux, exigindo sincronização com o backend.
   Já no Phoenix LiveView, o estado fica no processo do Elixir no servidor, sendo a única fonte da verdade. O front-end consome esse estado diretamente via WebSocket, recebendo apenas diffs de HTML.

## Conclusão

A partir desta experiência, consigo elaborar componentes HEEx (HTML/CSS) + Elixir, mantendo procedimento padrão de atenção à acessibilidade, semântica e organização visto a semelhança com TSX.

Sobre a arquitetura, acredito que o Elixir/OTP - Phoenix LiveView possui uma estrutura mais rigida e direcionada, assim como Angular, o que é bom, enquanto o React flexibiliza a arquitetura,ficando a cargo do desenvolvedor, o que pode ser perigoso se não pensar em desenvolvimento de forma escalável.

Em nenhum momento me senti limitado, consegui traçar paralelos com o react e não senti falta de nenhum recurso do react, sendo tudo adaptável. Props -> attr / children: slot :inner:block / etc...

A experiência demonstrou que o Phoenix LiveView é especialmente eficiente para aplicações orientadas a dados e tempo real, reduzindo a complexidade do frontend e centralizando regras de negócio no servidor.
Vejo grande potencial dessa stack para sistemas analíticos e dashboards, onde consistência de estado e simplicidade arquitetural são diferenciais críticos.

Em suma, fico feliz com o output do desafio - apesar de compreender da necessidade de um sênior real para revisão e auditoria do código - e fico inclinado a aprender melhor a stack, fico com o desafio de aprender a sintaxe do zero para implementação de um pequeno app de forma autônoma.
