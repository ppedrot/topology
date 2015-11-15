Require Import QArith Qcanon.

Require Import FunctionalExtensionality.

Record Qnn :=
  { qnn :> Qc
  ; nonneg : qnn >= 0
  }.

Local Open Scope Z.

Theorem Zle_irrel {x y : Z} (prf1 prf2 : x <= y) :
  prf1 = prf2. 
Proof. unfold Z.le in *.
apply functional_extensionality.
intros z. contradiction.
Qed.

Local Close Scope Z.
Local Close Scope Qc.

Definition Qle_irrel {x y : Q} (prf1 prf2 : x <= y)
  : prf1 = prf2 := Zle_irrel prf1 prf2.

Local Open Scope Qc.
Definition Qcle_irrel {x y : Qc} (prf1 prf2 : x <= y)
  : prf1 = prf2 := Qle_irrel prf1 prf2.

Definition Qnnle (x y : Qnn) : Prop :=
  x <= y.

Definition Qnnge (x y : Qnn) : Prop :=
  x >= y.

Definition Qnneq (x y : Qnn) : Prop := qnn x = qnn y.

Definition Qnnplus (x y : Qnn) : Qnn.
Proof.
refine ({| qnn := x + y |}).
replace 0 with (0 + 0) by field.
apply Qcplus_le_compat; destruct x, y; assumption.
Defined.

Definition Qnnmult (x y : Qnn) : Qnn.
Proof.
refine ({| qnn := x * y |}).
replace 0 with (0 * y) by field.
apply Qcmult_le_compat_r; apply nonneg.
Defined.

Definition Qnnzero : Qnn := Build_Qnn 0%Qc (Qcle_refl 0%Qc).

Definition Qnnone : Qnn.
Proof. apply (Build_Qnn 1%Qc). unfold Qle. simpl.
unfold Z.le. simpl. congruence.
Defined.

Theorem Qnneq_prop {x y : Qnn} :
  Qnneq x y -> x = y.
Proof. intros. destruct x, y. unfold Qnneq in H. simpl in H.
induction H. replace nonneg0 with nonneg1. reflexivity.
apply Qcle_irrel.
Qed.

Theorem Qnn_zero_prop {x : Qnn} :
  x <= 0 -> x = Qnnzero.
Proof.
intros. apply Qnneq_prop. unfold Qnneq.
unfold Qnnzero. simpl. apply Qcle_antisym.
assumption. apply nonneg.
Qed.

Infix "<=" := Qnnle : Qnn_scope.
Infix ">=" := Qnnge : Qnn_scope.
Infix "+" := Qnnplus : Qnn_scope.
Infix "*" := Qnnmult : Qnn_scope.
Infix "==" := Qnneq : Qnn_scope.

Notation "'0'" := Qnnzero : Qnn_scope.
Notation "'1'" := Qnnone : Qnn_scope.

Require Import Ring.

Theorem Qnnsrt : semi_ring_theory Qnnzero Qnnone
  Qnnplus Qnnmult eq.
Proof.
constructor; intros;
  match goal with
  | [  |- _ = _ ] => apply Qnneq_prop; unfold Qnneq
  end;
  try solve[simpl; field].
Qed.

Add Ring Qnn_Ring : Qnnsrt.

Local Close Scope Q.
Local Close Scope Qc.

Delimit Scope Qnn_scope with Qnn.

Local Open Scope Qnn.

Lemma Qnnle_refl (x : Qnn) : x <= x.
Proof. apply Qcle_refl. Qed.

Lemma Qnnle_trans {x y z : Qnn}
  : x <= y -> y <= z -> x <= z.
Proof. intros. eapply Qcle_trans; eassumption. Qed.

Lemma Qnnmult_le_compat {x y x' y' : Qnn}
  : x <= x' -> y <= y' -> x * y <= x' * y'.
Proof. intros.
assert (x * y <= x' * y).
apply Qcmult_le_compat_r. assumption. apply nonneg.
eapply Qnnle_trans. eassumption.
replace (x' * y) with (y * x') by ring.
replace (x' * y') with (y' * x') by ring.
apply Qcmult_le_compat_r. assumption. apply nonneg.
Qed.

(* Nonnegative lower reals *)
Record LPReal :=
  { lbound :> Qnn -> Prop
  ; zeroed : lbound 0
  ; dclosed : forall q, lbound q -> forall q', q' <= q -> lbound q'
  }.

Definition LPRle (r s : LPReal) : Prop :=
  forall q, r q -> s q.

Definition LPRge (r s : LPReal) : Prop :=
  forall q, s q -> r q.

Definition LPRle_refl (r : LPReal) : LPRle r r :=
  fun _ p => p.

Definition LPRle_trans {r s t : LPReal} 
  (rs : LPRle r s) (st : LPRle s t) : LPRle r t :=
  fun q prf => (st q (rs q prf)).

Definition LPReq (r s : LPReal) : Prop :=
  LPRle r s /\ LPRle s r.

Definition LPRQnn (q : Qnn) : LPReal.
Proof.
refine (
  {| lbound := fun q' => (q' <= q)%Qnn |}
).
- apply nonneg.
- intros. subst. eapply Qle_trans; eassumption.
Defined.

Definition LPRplus (x y : LPReal) : LPReal.
Proof.
refine (
  {| lbound := fun q => exists a b,
     lbound x a /\ lbound y b /\ (q <= a + b)%Qnn |}
).
- exists 0. exists 0. split. apply zeroed. split.
  apply zeroed. replace (0 + 0) with 0 by ring.
  apply Qnnle_refl.
- intros.
  destruct H as [a [b [xa [yb sum]]]].
  exists a. exists b. intuition. eapply Qnnle_trans; eassumption.
Defined.

Definition LPRmult (x y : LPReal) : LPReal.
Proof.
refine (
  {| lbound := fun q => exists a b,
     lbound x a /\ lbound y b /\ (q <= a * b)%Qnn |}
).
- exists 0. exists 0. split. apply zeroed. split.
  apply zeroed.
  replace (0 * 0) with 0 by ring. 
  apply Qnnle_refl.
- intros.
  destruct H as [a [b [xa [yb sum]]]].
  exists a. exists b. intuition. eapply Qnnle_trans; eassumption.
Defined.

Lemma LPReq_prop : forall r s, LPReq r s ->
  forall q, lbound r q <-> lbound s q.
Proof.
intros. destruct H. split. apply H. apply H0.
Qed.

Lemma LPReq_compat_OK 
  (propext : forall (x y : Prop), (x <-> y) -> x = y)
  (proof_irrel : forall (P : Prop) (x y : P), x = y)
  : forall r s, LPReq r s -> r = s. 
Proof.
intros. pose proof H as eq. destruct H.
unfold LPRle in *.
assert (lbound r = lbound s).
apply functional_extensionality.
intros q. apply propext. apply LPReq_prop.
assumption.
destruct r, s.
simpl in *. induction H1.
pose proof (proof_irrel _ zeroed0 zeroed1).
induction H1.
pose proof (proof_irrel _ dclosed0 dclosed1).
induction H1.
reflexivity.
Qed.

Axiom LPReq_compat : forall r s, LPReq r s -> r = s.

Theorem LPRsrt : semi_ring_theory (LPRQnn 0) (LPRQnn 1)
  LPRplus LPRmult eq.
Proof.
constructor; intros; apply LPReq_compat; unfold LPReq, LPRle;
repeat match goal with
| [ |- _ /\ _ ] => split
| [ |- forall _, _] => intros
| [ H : lbound (LPRQnn _) _ |- _ ] => simpl in H
| [ H : lbound (LPRplus _ _) _ |- _ ] => destruct H
| [ H : lbound (LPRmult _ _) _ |- _ ] => destruct H
| [ H : exists x, _ |- _ ] => destruct H
| [ H : _ /\ _ |- _ ] => destruct H
end.
- eapply dclosed; try eassumption.
  assert (x = 0).
  apply Qnn_zero_prop. assumption.
  subst.
  replace (0 + x0) with x0 in H1 by ring.
  assumption.
- simpl. exists 0. exists q. split. apply Qnnle_refl. split. assumption.
  replace (0 + q) with q by ring. apply Qnnle_refl.
- simpl. do 2 eexists. repeat split; try eassumption.
  replace (x0 + x) with (x + x0) by ring.
  assumption.
- simpl. do 2 eexists. repeat split; try eassumption.
  replace (x0 + x) with (x + x0) by ring.
  assumption.
- simpl. do 2 eexists. split.
  do 2 eexists. split. eassumption. split. eassumption.
  eapply Qnnle_refl.
  split. eassumption. eapply Qnnle_trans. eassumption.
  rewrite <- (SRadd_assoc Qnnsrt).
  apply Qcplus_le_compat. apply Qcle_refl.
  assumption.
- simpl. do 2 eexists. split. eassumption.
  split. do 2 eexists. split. eassumption. split. eassumption.
  eapply Qnnle_refl.
  eapply Qnnle_trans. eassumption.
  rewrite (SRadd_assoc Qnnsrt).
  apply Qcplus_le_compat. assumption. apply Qcle_refl.
- eapply dclosed. eassumption.
  eapply Qnnle_trans. eassumption.
  replace x0 with (1 * x0) at 2 by ring.
  apply Qcmult_le_compat_r. assumption.
  apply nonneg.
- simpl. exists 1. exists q. split. apply Qnnle_refl.
  split. assumption. replace (1 * q) with q by ring.
  apply Qnnle_refl.
- simpl. apply Qnn_zero_prop in H. subst.
  replace (0 * x0) with 0 in H1 by ring. assumption.
- apply Qnn_zero_prop in H. subst.
  simpl. exists 0. exists 0. split. apply Qnnle_refl. split.
  apply zeroed. replace (0 * 0) with 0 by ring.
  apply Qnnle_refl.
- simpl. do 2 eexists. split. eassumption. split.
  eassumption. replace (x0 * x) with (x * x0) by ring.
  assumption.
- simpl. do 2 eexists. split. eassumption. split.
  eassumption. replace (x0 * x) with (x * x0) by ring.
  assumption.
- simpl. do 2 eexists. split. do 2 eexists. split.
  eassumption. split. eassumption. eapply Qnnle_refl.
  split. eassumption. eapply Qnnle_trans. eassumption.
  rewrite <- (SRmul_assoc Qnnsrt).
  rewrite (SRmul_comm Qnnsrt).
  replace (x * (x1 * x2)) with ((x1 * x2) * x) by ring.
  apply Qcmult_le_compat_r. assumption.
  apply nonneg.
- simpl. do 2 eexists. split. eassumption. split. 
  do 2 eexists. split.
  eassumption. split. eassumption. eapply Qnnle_refl.
  eapply Qnnle_trans. eassumption.
  rewrite (SRmul_assoc Qnnsrt).
  apply Qcmult_le_compat_r. assumption.
  apply nonneg.
- simpl. do 2 eexists. split. do 2 eexists. split.
  eassumption. split. eassumption. apply Qnnle_refl.
  split. do 2 eexists. split. eassumption. split.
  eassumption. apply Qnnle_refl.
  rewrite <- (SRdistr_l Qnnsrt).
  eapply Qnnle_trans. eassumption.
  apply Qcmult_le_compat_r. eassumption. apply nonneg.
- destruct (Qccompare x2 x4) eqn:comp; 
  ((simpl; do 2 eexists; split);
   [ do 2 eexists; split; 
     [ eassumption 
     | split; [ eassumption | apply Qcle_refl ] ]
   | split ]).

  eassumption. eapply Qnnle_trans. eassumption.
  rewrite (SRdistr_l Qnnsrt).
  apply Qcplus_le_compat.
  apply Qceq_alt in comp. simpl. rewrite <- comp.
  assumption. assumption.

  apply H2. eapply Qnnle_trans. eassumption.
  rewrite (SRdistr_l Qnnsrt).
  apply Qcplus_le_compat.
  apply Qclt_alt in comp.
  apply Qclt_le_weak in comp.
  eapply Qcle_trans. eassumption.
  replace (x1 * x2) with (x2 * x1) by ring.
  replace (x1 * x4) with (x4 * x1) by ring.
  eapply Qcmult_le_compat_r. assumption. apply nonneg.
  assumption.

  apply H4. eapply Qnnle_trans. eassumption.
  rewrite (SRdistr_l Qnnsrt).
  apply Qcplus_le_compat. eassumption.
  eapply Qnnle_trans. eassumption.
  replace (x3 * x2) with (x2 * x3) by ring.
  replace (x3 * x4) with (x4 * x3) by ring.
  apply Qcmult_le_compat_r.
  apply Qcgt_alt in comp.
  apply Qclt_le_weak in comp. assumption. apply nonneg.
Qed.

Add Ring LPR_Ring : LPRsrt.

Infix "<=" := LPRle : LPR_scope.
Infix ">=" := LPRge : LPR_scope.
Infix "+" := LPRplus : LPR_scope.
Infix "*" := LPRmult : LPR_scope.

Notation "'0'" := (LPRQnn 0) : LPR_scope.
Notation "'1'" := (LPRQnn 1) : LPR_scope.

Delimit Scope LPR_scope with LPR.

Local Open Scope LPR.

Theorem LPRzero_min (r : LPReal) : 0 <= r.
Proof.
unfold LPRle. intros q Hq.
simpl in Hq. eapply dclosed.
apply zeroed. assumption.
Qed.

Definition LPRsup {A : Type} (f : A -> LPReal)
  : LPReal.
Proof.
refine (
  {| lbound := fun q => q = 0%Qnn \/ exists (idx : A), f idx q |}
).
- intros. left. reflexivity.
- intros. destruct H. subst. left. apply Qnn_zero_prop.
  assumption.
  right. destruct H. exists x. apply dclosed with q. assumption.
  assumption.
Defined.

Definition LPRinfinity : LPReal.
Proof. refine (
  {| lbound := fun q => True |}
); trivial.
Defined.

Theorem LPRinfinity_max (r : LPReal) : r <= LPRinfinity.
Proof.
unfold LPRle. intros. simpl. constructor.
Qed.

Lemma LPRsup_ge {A : Type} {f : A -> LPReal} {a : A} 
  : f a <= LPRsup f.
Proof. unfold LPRle. simpl. intros. right. eexists. eassumption.
Qed.

Lemma LPRsup_least {A : Type} {f : A -> LPReal}
  (a : A) : LPRsup f <= f a -> f a = LPRsup f.
Proof. intros.
apply LPReq_compat. split. apply LPRsup_ge. assumption.
Qed.

Theorem LPRle_antisym {x y : LPReal}
  : x <= y -> y <= x -> x = y.
Proof.
intros. apply LPReq_compat. split; assumption.
Qed.

Theorem LPRplus_le_compat {x y z t : LPReal}
  : (x <= y) -> (z <= t) -> (x + z <= y + t).
Proof. intros. unfold LPRle in *. intros.
simpl in *. destruct H1 as [a [b [H1 [H2 H3]]]].
do 2 eexists. split. apply H. eassumption. split. apply H0.
eassumption. assumption.
Qed.

Theorem LPRmult_le_compat {x x' y y' : LPReal}
  : x <= x' -> y <= y' -> x * y <= x' * y'.
Proof.
intros. unfold LPRle in *. intros.
simpl in *. destruct H1 as [a [b [H1 [H2 H3]]]].
do 2 eexists. split. apply H. eassumption. split.
apply H0. eassumption. assumption.
Qed.

Definition K {A} (x : A) {B} (y : B) := x.

Record Valuation {A : Type} :=
  { val :> (A -> Prop) -> LPReal
  ; strict : val (K False) = 0
  ; monotonic : forall (U V : A -> Prop), (forall z, U z -> V z)
              -> val U <= val V
  ; modular : forall {U V},
     val U + val V = val (fun z => U z /\ V z) + val (fun z => U z \/ V z)
  }.

Arguments Valuation : clear implicits.

Definition pointwise {A B : Type} (cmp : B -> B -> Prop)
  (f g : A -> B) : Prop := forall (a : A), cmp (f a) (g a).

Inductive Simple {A : Type} :=
  | SIndicator : (A -> Prop) -> Simple
  | SAdd : Simple -> Simple -> Simple
  | SScale : LPReal -> Simple -> Simple.

Arguments Simple : clear implicits.

Fixpoint SimpleIntegral {A : Type} (mu : (A -> Prop) -> LPReal) 
  (s : Simple A) : LPReal := match s with
  | SIndicator P => mu P
  | SAdd f g => SimpleIntegral mu f + SimpleIntegral mu g
  | SScale c f => c * SimpleIntegral mu f
  end.

Definition LPRindicator (P : Prop) : LPReal.
Proof. refine 
( {| lbound := fun q => q = 0%Qnn \/ (P /\ (q <= 1)%Qnn) |}).
- left. reflexivity.
- intros. destruct H.
  + left. subst. apply Qnneq_prop. unfold Qnneq. 
     apply Qcle_antisym. assumption. apply nonneg.
  + right. destruct H. split. assumption. eapply Qnnle_trans;
    eassumption.
Defined.

Lemma LPRind_bounded (P : Prop) : LPRindicator P <= 1.
Proof.
unfold LPRle; intros; simpl in *. destruct H. 
subst. apply nonneg. destruct H; assumption.
Qed.

Lemma LPRind_imp (P Q : Prop) (f : P -> Q)
  : LPRindicator P <= LPRindicator Q.
Proof.
unfold LPRle; intros; simpl in *. destruct H.
left. assumption. right. destruct H. split; auto.
Qed.

Lemma LPRind_true (P : Prop) : P -> LPRindicator P = 1.
Proof. intros. apply LPReq_compat.
split.
- apply LPRind_bounded.
- unfold LPRle; intros; simpl in *. right. split; assumption.
Qed.

Lemma LPRind_false (P : Prop) : ~ P -> LPRindicator P = 0.
Proof. intros. apply LPReq_compat. 
split.
- unfold LPRle; intros; simpl in *. 
  destruct H0. subst. apply Qcle_refl. destruct H0. contradiction.
- apply LPRzero_min.
Qed.

Definition unitProb {A} (a : A) (P : A -> Prop) : LPReal :=
  LPRindicator (P a).

(* Here we consider a Simple as a pointwise function, in a sense,
   by integrating against a Dirac delta. *)
Definition SimpleEval {A : Type} (f : Simple A) (x : A) : LPReal :=
  SimpleIntegral (unitProb x) f.

Record IntegralT (A : Type) :=
  { integral : (A -> LPReal) -> Valuation A -> LPReal
  ; int_simple_le : forall {s : Simple A} {f : A -> LPReal} {mu : Valuation A},
      pointwise LPRle (SimpleEval s) f
    -> SimpleIntegral mu s <= integral f mu
  ; int_simple_ge : forall {s : Simple A} {f : A -> LPReal} {mu : Valuation A},
      pointwise LPRle f (SimpleEval s)
    -> integral f mu <= SimpleIntegral mu s
  ; int_monotonic : forall {f g : A -> LPReal}
     , pointwise LPRle f g -> forall (mu : Valuation A)
     , integral f mu <= integral g mu
  ; int_adds : forall {f g : A -> LPReal} {mu : Valuation A}
     , integral f mu + integral g mu = integral (fun x => f x + g x) mu
  ; int_scales : forall {f : A -> LPReal} {c : LPReal} {mu : Valuation A}
     , c * integral f mu = integral (fun x => c * f x) mu
  }.

Axiom integration : forall (A : Type), IntegralT A.

Lemma int_simple {A : Type} {s : Simple A} {mu : Valuation A}
  : integral _ (integration A) (SimpleEval s) mu = SimpleIntegral mu s.
Proof.
apply LPReq_compat.
split.
- apply int_simple_ge. unfold pointwise. intros a. apply LPRle_refl.
- apply int_simple_le. unfold pointwise. intros a. apply LPRle_refl.
Qed.

Hint Resolve Qnnle_refl.

Lemma LPRind_mult {U V : Prop} :
  LPRindicator (U /\ V) = LPRindicator U * LPRindicator V.
Proof.
apply LPReq_compat. 
split; unfold LPRle; simpl in *; intros.
- destruct H.
  subst. exists 0%Qnn. exists 0%Qnn. intuition. 
  replace (0 * 0)%Qnn with 0%Qnn by ring. apply Qnnle_refl.
  exists 1%Qnn. exists 1%Qnn. intuition.
- destruct H as [a [b [pa [pb ab]]]].
  intuition; subst. left.  apply Qnn_zero_prop. assumption.
  left. apply Qnn_zero_prop. 
  replace (0 * b)%Qnn with 0%Qnn in ab by ring.
  assumption.
  left. apply Qnn_zero_prop.
  replace (a * 0)%Qnn with 0%Qnn in ab by ring.
  assumption.
  right. intuition. replace 1%Qnn with (1 * 1)%Qnn by ring.
  eapply Qnnle_trans. eassumption.
  apply Qnnmult_le_compat; assumption.
Qed.

Lemma LPRind_modular {U V : Prop} :
   LPRindicator U + LPRindicator V =
   LPRindicator (U /\ V) + LPRindicator (U \/ V).
Proof.
apply LPReq_compat; split; unfold LPRle; intros q H;
  destruct H as [x [y [px [py xy]]]]; 
  destruct px; subst; destruct py; subst; simpl.
- exists 0%Qnn. exists 0%Qnn. intuition.
- exists 0%Qnn. exists 1%Qnn. intuition.
  replace (0 + 1)%Qnn with 1%Qnn by ring.
  replace (0 + y)%Qnn with y%Qnn in xy by ring.
  eapply Qnnle_trans; eassumption.
- exists 0%Qnn. exists 1%Qnn. intuition. 
  replace (0 + 1)%Qnn with 1%Qnn by ring.
  replace (x + 0)%Qnn with x%Qnn in xy by ring.
  eapply Qnnle_trans; eassumption.
- exists 1%Qnn. exists 1%Qnn. intuition. eapply Qnnle_trans.
  eassumption. apply Qcplus_le_compat; assumption.
- exists 0%Qnn. exists 0%Qnn. intuition.
- intuition. 
  exists 1%Qnn. exists 0%Qnn. intuition. 
  replace (1 + 0)%Qnn with 1%Qnn by ring.
  replace (0 + y)%Qnn with y%Qnn in xy by ring.
  eapply Qnnle_trans; eassumption.
  exists 0%Qnn. exists 1%Qnn. intuition.
  replace (0 + 1)%Qnn with 1%Qnn by ring.
  replace (0 + y)%Qnn with y%Qnn in xy by ring.
  eapply Qnnle_trans; eassumption.
- exists 1%Qnn. exists 1%Qnn. intuition.
  eapply Qnnle_trans. eassumption.
  apply Qcplus_le_compat. assumption.
  apply nonneg.
- exists 1%Qnn. exists 1%Qnn. intuition;
  (eapply Qnnle_trans; [ eassumption
  | apply Qcplus_le_compat; assumption ]).
Qed.


Definition unit {A : Type} (a : A) : Valuation A.
Proof. refine (
 {| val := unitProb a |}
); intros.
- apply LPReq_compat. unfold LPReq. split.
  unfold unitProb. unfold LPRle. intros.
  destruct H. subst. simpl. apply Qcle_refl.
  destruct H. destruct H. apply LPRzero_min.
- unfold LPRle. intros q Hq. destruct Hq.
  left. assumption. right. destruct H0.
  split. apply H. assumption. assumption.
- unfold unitProb. apply LPRind_modular.
Defined.

(* Pushforward of a measure, i.e., map a function over a measure *)
Definition map {A B : Type} (f : A -> B) (v : Valuation A)
  : Valuation B.
Proof. refine (
  {| val := fun prop => val v (fun x => prop (f x)) |}
); intros.
- apply strict.
- apply monotonic.
  intros. apply H. assumption.
- apply modular; assumption.
Defined.

Lemma qredistribute : forall andLq andRq orLq orRq,
    andLq + andRq + (orLq + orRq)
 = (andLq + orLq) + (andRq + orRq).
Proof. intros. ring. Qed.

Lemma LPRplus_eq_compat : forall x y x' y',
  x = x' -> y = y' -> x + y = x' + y'.
Proof. intros. subst. reflexivity. Qed.

Definition add {A : Type} (ValL ValR : Valuation A) : Valuation A.
Proof. refine (
  {| val := fun P => ValL P + ValR P |}
); intros.
- rewrite strict. rewrite strict. ring.
- apply LPRplus_le_compat; apply monotonic; assumption.
- rewrite qredistribute. 
  rewrite (qredistribute (ValL (fun z => U z /\ V z))).
  apply LPRplus_eq_compat; apply modular.
Defined.

Lemma LPRmult_eq_compat : forall x y x' y',
  x = x' -> y = y' -> x * y = x' * y'.
Proof. intros. subst. reflexivity. Qed.

Definition scale {A : Type} (c : LPReal) 
  (Val : Valuation A) : Valuation A.
Proof. refine (
  {| val := fun P => c * Val P |}
); intros.
- rewrite strict. ring.
- apply LPRmult_le_compat. apply LPRle_refl.
  apply monotonic; assumption.
- replace (c * Val U + c * Val V) with (c * (Val U + Val V)) by ring.
  replace (c * Val _ + c * Val _) 
  with (c * (Val (fun z : A => U z /\ V z) + Val (fun z : A => U z \/ V z))) by ring.
  apply LPRmult_eq_compat. reflexivity.
  apply modular.
Qed.

Definition Valle {A : Type} (val1 val2 : Valuation A) : Prop :=
  forall (P : A -> Prop), val1 P <= val2 P.

Lemma Valle_refl {A : Type} (val : Valuation A) : Valle val val.
Proof. unfold Valle. intros. apply LPRle_refl. Qed.

Lemma Valle_trans {A : Type} (x y z : Valuation A)
  : Valle x y -> Valle y z -> Valle x z.
Proof. intros. unfold Valle in *. intros P.
eapply LPRle_trans. apply H. apply H0.
Qed.

Definition Valeq {A : Type} (val1 val2 : Valuation A) : Prop :=
  forall (P : A -> Prop), val1 P = val2 P.

Lemma Valle_antisym {A : Type} (x y : Valuation A)
  : Valle x y -> Valle y x -> Valeq x y.
Proof. intros. unfold Valle, Valeq in *. intros.
apply LPRle_antisym. apply H. apply H0.
Qed.

Lemma Valeq_compat_OK 
  (proof_irrel : forall (P : Prop) (x y : P), x = y)
  { A : Type }
  : forall (mu nu : Valuation A), Valeq mu nu -> mu = nu. 
Proof.
intros.
unfold Valeq in *.
destruct mu, nu. simpl in *.
assert (val0 = val1).
apply functional_extensionality. assumption.
induction H0.
pose proof (proof_irrel _ strict0 strict1).
induction H0.
pose proof (proof_irrel _ monotonic0 monotonic1).
induction H0.
pose proof (proof_irrel _ modular0 modular1).
induction H0.
reflexivity.
Qed.

Axiom Valeq_compat : forall (A : Type) (mu nu : Valuation A)
  , Valeq mu nu -> mu = nu.

Lemma Valplus_comm {A : Type} : forall {x y : Valuation A}
  , add x y = add y x.
Proof.
intros. apply Valeq_compat.
unfold Valeq. intros. simpl. ring.
Qed.

Lemma integral_zero {A : Type} : forall {mu : Valuation A}
  , integral A (integration A) (SimpleEval (SIndicator (K False))) mu = 0.
Proof.
intros.
rewrite int_simple. simpl. apply strict.
Qed.

Lemma int_pointwise_eq {A : Type} : 
  forall (f g : A -> LPReal), pointwise LPReq f g ->
  forall (mu : Valuation A),
  integral _ (integration A) f mu = integral _ (integration A) g mu.
Proof.
intros. apply LPReq_compat. unfold pointwise in H.
unfold LPReq. split; apply int_monotonic; unfold pointwise;
apply H.
Qed.

Definition bind {A B : Type}
  (v : Valuation A) (f : A -> Valuation B)
  : Valuation B.
Proof. refine (
  {| val := fun P => integral A (integration A) (fun x => (f x) P) v |}
).
- apply LPReq_compat. unfold LPReq. split.
  erewrite <- integral_zero.
  apply int_monotonic.
  unfold pointwise. intros.
  rewrite strict. apply LPRzero_min.
  apply LPRzero_min.
- intros. apply int_monotonic.
  unfold pointwise. intros.
  apply monotonic. assumption.
- intros. do 2 rewrite int_adds. apply int_pointwise_eq.
  unfold pointwise. intros a.
  assert (
((f a) U + (f a) V) =
((f a) (fun z : B => U z /\ V z) + (f a) (fun z : B => U z \/ V z))
). apply modular. rewrite H. split; apply LPRle_refl.
Defined.

Definition product {A B : Type}
  (muA : Valuation A) (muB : Valuation B)
  : Valuation (A * B) := 
  bind muA (fun a => map (fun b => (a, b)) muB).

Theorem int_dirac_simple {A : Type} {s : Simple A} {a : A} :
 integral A (integration A) (SimpleEval s) (unit a) = SimpleEval s a.
Proof.
rewrite int_simple. unfold SimpleEval. 
induction s; simpl; reflexivity.
Qed.

Theorem int_indicator {A : Type} {P : A -> Prop} {mu : Valuation A}
  : integral A (integration A) (fun x => LPRindicator (P x)) mu = mu P.
Proof.
rewrite int_pointwise_eq with (g := SimpleEval (SIndicator P)).
rewrite int_simple. simpl. reflexivity.
unfold SimpleEval. simpl. unfold unitProb.
unfold pointwise. intros. split; apply LPRle_refl.
Qed.

Theorem int_dirac {A : Type} {f : A -> LPReal} {a : A}
  (dec_eq : forall a', {a = a'} + {a <> a'}) :
  integral A (integration A) f (unit a) = f a.
Proof.
intros. apply LPReq_compat. split.
- pose (SAdd 
      (SScale (LPRsup f) (SIndicator (fun a' => a <> a')))
      (SScale (f a) (SIndicator (fun a' => a = a')))).
  eapply LPRle_trans.
  + apply int_simple_ge.
   instantiate (1 := s).
   unfold pointwise. intros. unfold SimpleEval.
   simpl. unfold unitProb.
   destruct (dec_eq a0).
   * replace (f a0) with (0 + f a0 * 1) by ring.
    subst.
    apply LPRplus_le_compat. apply LPRzero_min.
    apply LPRmult_le_compat. apply LPRle_refl.
    unfold LPRle. intros. simpl in *.
    right. split. reflexivity. assumption.
   * replace (f a0) with (f a0 * 1 + 0) by ring.
    apply LPRplus_le_compat. apply LPRmult_le_compat.
    apply LPRsup_ge. unfold LPRle. intros. simpl in *.
    right. split; assumption. apply LPRzero_min.
  + simpl. replace (f a) with (0 + f a * 1) at 2 by ring.
    apply LPRplus_le_compat. unfold unitProb.
    rewrite LPRind_false.
    replace (LPRsup f * 0) with 0 by ring. apply LPRle_refl.
    intuition.
    apply LPRmult_le_compat. apply LPRle_refl.
    unfold unitProb. rewrite LPRind_true. apply LPRle_refl.
    reflexivity.
- pose (SScale (f a) (SIndicator (fun a' => a = a'))).
  eapply LPRle_trans.
  Focus 2. apply int_simple_le. instantiate (1 := s).
  unfold pointwise. intros a'. unfold SimpleEval.
  simpl. unfold unitProb. 
  destruct (dec_eq a'). 
  + replace (f a') with (f a' * 1) by ring.
    subst. apply LPRmult_le_compat. apply LPRle_refl.
    rewrite LPRind_true. apply LPRle_refl. reflexivity.
  + simpl. unfold unitProb. rewrite LPRind_true.
    replace (f a * 1) with (f a) by ring.
    apply LPRle_refl. reflexivity.
  + rewrite LPRind_false. replace (f a * 0) with 0 by ring.
    apply LPRzero_min. assumption.
Qed.

Theorem unitProdId {A B : Type}
  (a : A) (deceq : forall a', {a = a'} + {a <> a'})
  (muB : Valuation B)
  (P : (A * B) -> Prop)
  : product (unit a) muB P = muB (fun b => P (a, b)).
Proof. simpl. rewrite int_dirac. reflexivity. assumption. Qed.

Lemma LPReq_refl (x : LPReal) : LPReq x x.
Proof. split; apply LPRle_refl. Qed.

Lemma LPReq_trans (x y z : LPReal) 
  : LPReq x y -> LPReq y z -> LPReq x z.
Proof. intros. destruct H; destruct H0; split;
  eapply LPRle_trans; eassumption.
Qed.

Lemma LPReq_compat_backwards (x y : LPReal) : x = y -> LPReq x y.
Proof. intros H; induction H; apply LPReq_refl. Qed.

Theorem product_prop {A B : Type}
  (muA : Valuation A)
  (muB : Valuation B)
  (PA : A -> Prop) (PB : B -> Prop)
  : (product muA muB) (fun p => let (x, y) := p in PA x /\ PB y)
  = muA PA * muB PB.
Proof. simpl.
rewrite <- int_indicator.
rewrite (SRmul_comm LPRsrt).
rewrite int_scales.
apply int_pointwise_eq. unfold pointwise.
intros a.
do 2 rewrite <- int_indicator.
rewrite (SRmul_comm LPRsrt).
rewrite int_scales.
eapply LPReq_compat_backwards.
apply int_pointwise_eq.
unfold pointwise. intros.
rewrite LPRind_mult.
apply LPReq_refl.
Qed.