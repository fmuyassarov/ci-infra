install_requirements:
	./packages.sh

kubeadm_init:
	./kubeadm/master-1/setup_ha.sh

kubeadm_join_master2:
	./kubeadm/master-1/setup_ha.sh

kubeadm_join_master3:
	./kubeadm/master-1/setup_ha.sh

.PHONY: kubeadm_init kubeadm_join_master2 kubeadm_join_master3
