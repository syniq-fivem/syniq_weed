const app = Vue.createApp({
  data() {
        return {
            showStatus: false,
            status: {
                growth: 0,
                health: 0,
                water: 0,
                fertilizer: 0
            },
            label: 'Weed',
            plantId: 0,
        }
    },
    computed: {
        truncate(text, maxLength) {
            if (!text) return ''
            console.log(text.length)
            return text.length > maxLength ? text.slice(0, maxLength) + '...' : text
        },
    },
    methods: {
        closeMenu() {
            this.showStatus = false
            fetch(`https://${GetParentResourceName()}/closeMenu`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        },

        feedPlant(type) {
            fetch(`https://${GetParentResourceName()}/feedPlant`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    type: type,
                    id: this.plantId
                })
            });
        },

        harvestPlant() {
            fetch(`https://${GetParentResourceName()}/harvestPlant`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    id: this.plantId
                })
            }).then(res => res.json())
            .then(close => {
                console.log('Carry plant callback response:', close);
                if (close) {
                    this.closeMenu()
                }
            });
        },

        destroyPlant() {
            fetch(`https://${GetParentResourceName()}/destroyPlant`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    id: this.plantId
                })
            }).then(res => res.json())
            .then(close => {
                if (close) {
                    this.closeMenu()
                }
            });
        },

        carryPlant() {
            this.closeMenu()
            fetch(`https://${GetParentResourceName()}/carryPlant`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    id: this.plantId
                })
            });
        },
    },
    mounted() {
        window.addEventListener('message', (event) => {
            const data = event.data
            switch (data.action) {
                case 'openStatus':
                    this.showStatus = true
                    this.label = data.label
                    this.plantId = data.id
                    this.status = data.status
                    this.locales = data.locales
                    break

                case 'updateStatus':
                    this.status = data.status
                    break
            };
        });

        window.addEventListener('keyup', (e) => {
            if (e.key === 'Escape') {
                this.closeMenu()
            };
        });
    }
}).mount('#app')