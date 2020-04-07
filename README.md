# advpl_react_controle_acessos_backend

<p>O ERP Protheus possui uma boa estrutura de controle de acessos e permissões, porém nunca estamos satisfeitos e sempre queremos mais.</p>

<p>Pensando nesse cenário trarei uma sequência de postagens com o objetivo de construirmos juntos uma camada extra de controle de acessos às rotinas padrões, aplicando o conceito de backend utilizando o<strong> Advpl com REST </strong>e o frontend utilizando a biblioteca javascript <strong>ReactJS.</strong></p>

<h3>Objetivo</h3>

<p>Construir uma customização no ERP Protheus que possibilite controlar o acesso de usuários nas rotinas padrões, permitindo que esse controle seja realizado por rotina e para cada botão disponível nessa rotina.</p>

<p>Toda manutenção dessa processo será realizado através de interface web e integrada com o ERP Protheus através de<strong> API REST.</strong></p>

<p>O objetivo dessa ferramenta é didático, utilize por conta e risco.</p>

<h3>Funcionalidades</h3>

<ul><li>Permitir acesso nas rotinas configuradas para apenas usuários autorizados.</li><li>Controlar o acesso a nível de botões existentes na rotina.</li><li>Garantir que mesmo o usuário possuindo a rotina no menu, não poderá realizar ações a menos que isso seja previamente autorizado.</li></ul>

<h3>Requisitos</h3>

<ul><li>Criação de tabela para controle das permissões</li><li>Utilização de ponto de entrada para validar as permissões</li><li>Utilização da SX5 para controle das rotinas a serem monitoradas</li><li>ReactJS</li></ul>
