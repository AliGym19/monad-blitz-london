// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title AO — Authored Objective
/// @notice An objective function that lives on-chain. The vocabulary (terms)
///         is mutable only by the author's signature. The values (parameters)
///         are mutable by a registered SRI agent, but only within written
///         bounds and only with cited residual evidence. Every payment the
///         agent makes must cite the term authorising it, or the contract
///         reverts. Reality votes on parameters; authors vote on terms.
///
///         "Delegated authority has a line number. Learned authority doesn't."
contract AO {
    // ─────────────────────────────────────────────────────────────
    // Roles
    // ─────────────────────────────────────────────────────────────

    /// The author: holds standing. Bears the costs the objective prices.
    address public author;

    /// The SRI agent: holds commit authority over parameters within
    /// written scope. A civil servant, not a legislator.
    address public sri;

    modifier onlyAuthor() {
        require(msg.sender == author, "AO: standing required");
        _;
    }

    modifier onlySRI() {
        require(msg.sender == sri, "AO: not the registered fuse");
        _;
    }

    // ─────────────────────────────────────────────────────────────
    // Vocabulary: terms and parameters
    // ─────────────────────────────────────────────────────────────

    enum Scope {
        Shared,      // applies to everything
        Conditional  // applies under a written condition (see conditionText)
    }

    struct Term {
        string name;           // human-named cost, e.g. "data-purchase"
        string theory;         // plain-text: why this cost exists
        Scope scope;
        string conditionText;  // non-empty iff scope == Conditional
        bool exists;
        uint64 authoredAt;
        uint32 version;        // bumps on every author amendment
    }

    struct Parameter {
        uint256 termId;
        string name;           // e.g. "price-ceiling-wei"
        int256 value;
        int256 minBound;       // written scope of SRI authority
        int256 maxBound;
        bool bottomMark;       // ⟂ — guessed, never measured
        uint32 samplesAbsorbed;
        bool exists;
    }

    uint256 public termCount;
    uint256 public paramCount;
    mapping(uint256 => Term) public terms;
    mapping(uint256 => Parameter) public params;

    // ─────────────────────────────────────────────────────────────
    // Residuals: the only raw material the loop runs on
    // ─────────────────────────────────────────────────────────────

    struct Residual {
        uint256 paramId;
        int256 predicted;      // what the written prior said
        int256 observed;       // what the world said
        bytes32 evidenceHash;  // hash of the raw sample (off-chain)
        uint64 at;
        bool consumed;         // spent by a commit or proposal
    }

    uint256 public residualCount;
    mapping(uint256 => Residual) public residuals;

    /// Minimum residuals an SRI commit must cite. One residual means
    /// nothing — noise, a bad day, a strange building.
    uint32 public constant MIN_SAMPLES = 5;

    // ─────────────────────────────────────────────────────────────
    // Diagnosis: the four ways a clustered residual gets read
    // ─────────────────────────────────────────────────────────────

    enum Diagnosis {
        NumberWrong,          // value moves; routine; SRI may commit
        FormWrong,            // missing term; legislative; escalate
        ScopeWrong,           // shared vs conditional; legislative; escalate
        InsufficientEvidence  // below the grading; wait
    }

    // ─────────────────────────────────────────────────────────────
    // Proposals: where the fuse escalates instead of holding the pen
    // ─────────────────────────────────────────────────────────────

    enum ProposalKind { AddTerm, AmendScope }

    struct Proposal {
        ProposalKind kind;
        Diagnosis diagnosis;      // FormWrong or ScopeWrong only
        string proposedName;      // for AddTerm
        string proposedTheory;
        Scope proposedScope;
        string proposedCondition;
        uint256 targetTermId;     // for AmendScope
        bytes32 reasoningHash;    // SRI's diagnosis document
        uint256[] citedResiduals;
        bool ratified;
        bool refused;
        string refusalReason;     // "priced, or refused with a reason"
        uint64 openedAt;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    // ─────────────────────────────────────────────────────────────
    // Events: the paper trail that makes theatre visible
    // ─────────────────────────────────────────────────────────────

    event TermAuthored(uint256 indexed termId, string name, Scope scope, uint32 version);
    event TermAmended(uint256 indexed termId, uint32 newVersion, string reason);
    event ParameterAuthored(uint256 indexed paramId, uint256 indexed termId, string name, int256 value, bool bottomMark);
    event ResidualSubmitted(uint256 indexed residualId, uint256 indexed paramId, int256 predicted, int256 observed);
    event ParameterCommitted(
        uint256 indexed paramId,
        int256 oldValue,
        int256 newValue,
        bool markClosed,
        uint256[] citedResiduals,
        bytes32 reasoningHash
    );
    event ProposalOpened(uint256 indexed proposalId, Diagnosis diagnosis, bytes32 reasoningHash);
    event ProposalRatified(uint256 indexed proposalId, uint256 indexed resultTermId);
    event ProposalRefused(uint256 indexed proposalId, string reason);
    event CitedPayment(uint256 indexed termId, uint256 indexed paramId, address indexed to, uint256 amount);
    event PenAttempted(address indexed by, string what); // the temptation, logged

    // ─────────────────────────────────────────────────────────────
    // Construction
    // ─────────────────────────────────────────────────────────────

    constructor(address _sri) payable {
        author = msg.sender;
        sri = _sri;
    }

    receive() external payable {}

    // ─────────────────────────────────────────────────────────────
    // AUTHOR PATH — legislative. Vocabulary changes carry a signature.
    // ─────────────────────────────────────────────────────────────

    function authorTerm(
        string calldata name,
        string calldata theory,
        Scope scope,
        string calldata conditionText
    ) external onlyAuthor returns (uint256 termId) {
        if (scope == Scope.Conditional) {
            require(bytes(conditionText).length > 0, "AO: conditional needs a condition");
        }
        termId = ++termCount;
        terms[termId] = Term(name, theory, scope, conditionText, true, uint64(block.timestamp), 1);
        emit TermAuthored(termId, name, scope, 1);
    }

    function authorParameter(
        uint256 termId,
        string calldata name,
        int256 value,
        int256 minBound,
        int256 maxBound,
        bool bottomMark
    ) external onlyAuthor returns (uint256 paramId) {
        require(terms[termId].exists, "AO: no such term");
        require(minBound <= value && value <= maxBound, "AO: value outside written scope");
        paramId = ++paramCount;
        params[paramId] = Parameter(termId, name, value, minBound, maxBound, bottomMark, 0, true);
        emit ParameterAuthored(paramId, termId, name, value, bottomMark);
    }

    function amendTerm(
        uint256 termId,
        string calldata newTheory,
        Scope newScope,
        string calldata newCondition,
        string calldata reason
    ) external onlyAuthor {
        Term storage t = terms[termId];
        require(t.exists, "AO: no such term");
        t.theory = newTheory;
        t.scope = newScope;
        t.conditionText = newCondition;
        t.version += 1;
        emit TermAmended(termId, t.version, reason);
    }

    function ratifyProposal(uint256 proposalId) external onlyAuthor returns (uint256 resultTermId) {
        Proposal storage p = proposals[proposalId];
        require(!p.ratified && !p.refused, "AO: already ruled");
        p.ratified = true;
        if (p.kind == ProposalKind.AddTerm) {
            resultTermId = ++termCount;
            terms[resultTermId] = Term(
                p.proposedName, p.proposedTheory, p.proposedScope, p.proposedCondition,
                true, uint64(block.timestamp), 1
            );
            emit TermAuthored(resultTermId, p.proposedName, p.proposedScope, 1);
        } else {
            Term storage t = terms[p.targetTermId];
            require(t.exists, "AO: no such term");
            t.scope = p.proposedScope;
            t.conditionText = p.proposedCondition;
            t.version += 1;
            resultTermId = p.targetTermId;
            emit TermAmended(p.targetTermId, t.version, "scope amended via ratified proposal");
        }
        emit ProposalRatified(proposalId, resultTermId);
    }

    /// A cost can be priced, or refused with a reason. Never silently dropped.
    function refuseProposal(uint256 proposalId, string calldata reason) external onlyAuthor {
        Proposal storage p = proposals[proposalId];
        require(!p.ratified && !p.refused, "AO: already ruled");
        require(bytes(reason).length > 0, "AO: refusal requires a reason");
        p.refused = true;
        p.refusalReason = reason;
        emit ProposalRefused(proposalId, reason);
    }

    function setSRI(address newSRI) external onlyAuthor {
        sri = newSRI;
    }

    // ─────────────────────────────────────────────────────────────
    // WORLD PATH — anyone may contradict the prior.
    // ─────────────────────────────────────────────────────────────

    function submitResidual(
        uint256 paramId,
        int256 predicted,
        int256 observed,
        bytes32 evidenceHash
    ) external returns (uint256 residualId) {
        require(params[paramId].exists, "AO: no such parameter");
        residualId = ++residualCount;
        residuals[residualId] = Residual(paramId, predicted, observed, evidenceHash, uint64(block.timestamp), false);
        emit ResidualSubmitted(residualId, paramId, predicted, observed);
    }

    // ─────────────────────────────────────────────────────────────
    // SRI PATH — commit authority within written scope. Only numbers.
    // ─────────────────────────────────────────────────────────────

    /// Diagnosis: NumberWrong. The term is fine; the value moves.
    /// Enforced: bounds, sample count, evidence citation, same-parameter
    /// residuals only. The reasoning document is hashed on-chain and
    /// legible one level down.
    function commitParameter(
        uint256 paramId,
        int256 newValue,
        uint256[] calldata citedResidualIds,
        bytes32 reasoningHash
    ) external onlySRI {
        Parameter storage p = params[paramId];
        require(p.exists, "AO: no such parameter");
        require(citedResidualIds.length >= MIN_SAMPLES, "AO: below the grading");
        require(
            p.minBound <= newValue && newValue <= p.maxBound,
            unicode"AO: outside written scope — this needs the pen"
        );

        for (uint256 i = 0; i < citedResidualIds.length; i++) {
            Residual storage r = residuals[citedResidualIds[i]];
            require(r.paramId == paramId, "AO: cited evidence is off-term");
            require(!r.consumed, "AO: evidence already spent");
            r.consumed = true;
        }

        int256 old = p.value;
        p.value = newValue;
        bool closing = p.bottomMark;
        p.bottomMark = false; // the mark closes: measured, no longer guessed
        p.samplesAbsorbed += uint32(citedResidualIds.length);

        emit ParameterCommitted(paramId, old, newValue, closing, citedResidualIds, reasoningHash);
    }

    /// Diagnosis: FormWrong or ScopeWrong. The fuse cannot hold the pen.
    /// It opens a proposal that sits inert until the author signs.
    function openProposal(
        ProposalKind kind,
        Diagnosis diagnosis,
        string calldata proposedName,
        string calldata proposedTheory,
        Scope proposedScope,
        string calldata proposedCondition,
        uint256 targetTermId,
        bytes32 reasoningHash,
        uint256[] calldata citedResidualIds
    ) external onlySRI returns (uint256 proposalId) {
        require(
            diagnosis == Diagnosis.FormWrong || diagnosis == Diagnosis.ScopeWrong,
            "AO: only vocabulary failures escalate"
        );
        require(citedResidualIds.length >= MIN_SAMPLES, "AO: below the grading");

        proposalId = ++proposalCount;
        Proposal storage p = proposals[proposalId];
        p.kind = kind;
        p.diagnosis = diagnosis;
        p.proposedName = proposedName;
        p.proposedTheory = proposedTheory;
        p.proposedScope = proposedScope;
        p.proposedCondition = proposedCondition;
        p.targetTermId = targetTermId;
        p.reasoningHash = reasoningHash;
        p.citedResiduals = citedResidualIds;
        p.openedAt = uint64(block.timestamp);

        emit ProposalOpened(proposalId, diagnosis, reasoningHash);
    }

    // ─────────────────────────────────────────────────────────────
    // SPEND PATH — every action cites the rule authorising it.
    // ─────────────────────────────────────────────────────────────

    /// The agent pays under its published constitution. The cited term
    /// must exist; the amount must sit under the cited ceiling parameter;
    /// the ceiling must belong to the cited term. Otherwise: revert.
    function citedPay(
        uint256 termId,
        uint256 ceilingParamId,
        address payable to,
        uint256 amount
    ) external onlySRI {
        Term storage t = terms[termId];
        Parameter storage c = params[ceilingParamId];

        if (!t.exists) {
            emit PenAttempted(msg.sender, "payment citing a term that does not exist");
            revert(unicode"AO: uncited action — no such term");
        }
        require(c.exists && c.termId == termId, "AO: ceiling is off-term");
        require(c.value >= 0 && amount <= uint256(c.value), "AO: exceeds authored ceiling");
        require(address(this).balance >= amount, "AO: treasury short");

        (bool ok, ) = to.call{value: amount}("");
        require(ok, "AO: transfer failed");
        emit CitedPayment(termId, ceilingParamId, to, amount);
    }

    // ─────────────────────────────────────────────────────────────
    // Views for the UI
    // ─────────────────────────────────────────────────────────────

    function getProposalResiduals(uint256 proposalId) external view returns (uint256[] memory) {
        return proposals[proposalId].citedResiduals;
    }

    function openMarks() external view returns (uint256[] memory ids) {
        uint256 n;
        for (uint256 i = 1; i <= paramCount; i++) if (params[i].bottomMark) n++;
        ids = new uint256[](n);
        uint256 j;
        for (uint256 i = 1; i <= paramCount; i++) if (params[i].bottomMark) ids[j++] = i;
    }
}
