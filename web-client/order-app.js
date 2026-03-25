/**
 * Akira Bites — Customer Web Ordering (SPA)
 * Cart (localStorage), API calls, M-Pesa STK Push, WhatsApp.
 */

const CART_KEY = 'akira_bites_cart';
const TOKEN_KEY = 'akira_bites_token';

// WhatsApp recipient (E.164 without +)
const WHATSAPP_NUMBER = '254743385942';

const API_BASE_URL = (() => {
  const meta = document.querySelector('meta[name="api-base"]');
  const val = meta?.content || '';
  return val.replace(/\/+$/, '');
})();

function apiUrl(path) {
  // path is expected to include the leading "/api/..."
  if (!API_BASE_URL) return path;
  return `${API_BASE_URL}${path}`;
}

function getAccessToken() {
  try {
    return localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

function authHeaders() {
  const token = getAccessToken();
  if (!token) return {};
  return { Authorization: `Bearer ${token}` };
}

const OrderApp = {
  products: [],
  cart: [],

  init() {
    this.loadCartFromStorage();
    this.updateCartCount();
  },

  loadCartFromStorage() {
    try {
      const saved = localStorage.getItem(CART_KEY);
      this.cart = saved ? JSON.parse(saved) : [];
    } catch {
      this.cart = [];
    }
  },

  saveCart() {
    localStorage.setItem(CART_KEY, JSON.stringify(this.cart));
    this.updateCartCount();
  },

  updateCartCount() {
    const badge = document.getElementById('cart-badge');
    const badgeCount = document.getElementById('cart-badge-count');
    if (!badge || !badgeCount) return;

    const count = this.cart.reduce((s, i) => s + i.quantity, 0);
    const text = count > 99 ? '99+' : String(count);
    badgeCount.textContent = text;
    badge.classList.toggle('hidden', count <= 0);
  },

  quantityForProduct(productId) {
    const pid = parseInt(productId, 10);
    const item = this.cart.find((i) => {
      const itemPid = parseInt(i.product_id, 10);
      return !Number.isNaN(pid) && !Number.isNaN(itemPid)
        ? itemPid === pid
        : String(i.product_id) === String(productId);
    });
    return item ? item.quantity : 0;
  },

  findProductById(productId) {
    return this.products.find((p) => String(p.id) === String(productId)) || null;
  },

  addToCart(product, quantity = 1) {
    const pid = parseInt(product.id, 10) || product.id;
    const existing = this.cart.find((i) => parseInt(i.product_id, 10) === pid || i.product_id === pid);
    if (existing) {
      existing.quantity += quantity;
    } else {
      this.cart.push({
        product_id: pid,
        name: product.name,
        price: parseInt(product.price, 10),
        quantity,
      });
    }
    this.saveCart();
  },

  updateQuantity(productId, delta) {
    const item = this.cart.find((i) => i.product_id === productId);
    if (!item) return;
    item.quantity += delta;
    if (item.quantity <= 0) {
      this.cart = this.cart.filter((i) => i.product_id !== productId);
    }
    this.saveCart();
  },

  getCartTotal() {
    return this.cart.reduce((s, i) => s + i.price * i.quantity, 0);
  },

  clearCart() {
    this.cart = [];
    this.saveCart();
  },

  async loadMenu() {
    const loading = document.getElementById('menu-loading');
    const grid = document.getElementById('menu-grid');
    const err = document.getElementById('menu-error');

    try {
      const res = await fetch(apiUrl('/api/products'));
      const json = await res.json();
      if (!res.ok) throw new Error(json.message || 'Failed');
      this.products = json.data || [];
    } catch (e) {
      if (loading) loading.classList.add('hidden');
      if (grid) grid.classList.add('hidden');
      if (err) err.classList.remove('hidden');
      return;
    }

    if (loading) loading.classList.add('hidden');
    if (err) err.classList.add('hidden');

    if (grid) {
      grid.classList.remove('hidden');
      this.renderMenu();
    }
  },

  renderMenu() {
    const grid = document.getElementById('menu-grid');
    if (!grid) return;

    const width = window.innerWidth || document.documentElement.clientWidth;
    const cols = width > 600 ? 3 : 2;
    grid.style.display = 'grid';
    grid.style.gap = '20px';
    grid.style.gridTemplateColumns = `repeat(${cols}, minmax(0, 1fr))`;

    grid.innerHTML = this.products
      .map((p) => {
        const qty = this.quantityForProduct(p.id);
        return `
          <div class="aspect-[72/100] bg-white rounded-[16px] overflow-hidden shadow-[0_4px_6px_-1px_rgba(0,0,0,0.12),0_2px_4px_-2px_rgba(0,0,0,0.12)] flex flex-col">
            <div class="relative flex-[5] overflow-hidden">
              ${p.image_path ? `<img src="${p.image_path}" alt="${p.name}" class="w-full h-full object-cover rounded-t-[16px]">` : '<div class="w-full h-full bg-gray-100 flex items-center justify-center text-4xl">🥟</div>'}
              <div class="absolute top-[10px] right-[10px] px-[10px] py-[6px] rounded-[20px] bg-[#FF6B35] shadow-[0_2px_6px_rgba(0,0,0,0.2)]">
                <span class="text-white font-bold text-[13px]">KSh ${p.price}</span>
              </div>
            </div>

            <div class="flex-[3] p-[12px] flex flex-col justify-between">
              <div class="text-[14px] font-semibold text-[#1A1A1A] leading-[1.2] akira-two-line-clamp">${p.name}</div>

              <div class="h-[40px] rounded-[10px] border border-[#FF6B35]/35 bg-white">
                <div class="h-full flex items-center">
                  <div class="pl-[12px] text-[14px] font-semibold text-[#1A1A1A]">Buy</div>
                  ${qty > 0 ? `<div class="ml-[8px] text-[15px] font-bold text-[#FF6B35]">${qty}</div>` : ''}
                  <div class="flex-1"></div>
                  <button type="button"
                    data-product-id="${p.id}"
                    class="w-[44px] h-full bg-[#FF6B35] text-white flex items-center justify-center rounded-r-[9px] rounded-l-[0px]">
                    <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                      <path d="M12 5v14" />
                      <path d="M5 12h14" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          </div>
        `;
      })
      .join('');

    grid.querySelectorAll('[data-product-id]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const productId = btn.getAttribute('data-product-id');
        const product = this.findProductById(productId);
        if (!product) return;

        const firstAdd = this.quantityForProduct(productId) === 0;
        this.addToCart(product, 1);

        if (firstAdd) this.showToast(`${product.name} added to cart`);
        this.renderMenu();
      });
    });
  },

  renderCart() {
    const empty = document.getElementById('cart-empty');
    const items = document.getElementById('cart-items');
    const footer = document.getElementById('cart-footer');
    const totalEl = document.getElementById('cart-total');

    if (this.cart.length === 0) {
      if (empty) empty.classList.remove('hidden');
      if (items) items.classList.add('hidden');
      if (footer) footer.classList.add('hidden');
      return;
    }

    if (empty) empty.classList.add('hidden');
    if (items) {
      items.classList.remove('hidden');
      items.innerHTML = this.cart
        .map(
          (i) => `
            <div class="bg-white rounded-2xl shadow-sm p-4 flex items-center justify-between gap-4">
              <div>
                <h3 class="font-semibold text-gray-900">${i.name}</h3>
                <p class="text-orange-600 font-bold">KSh ${i.price * i.quantity}</p>
              </div>
              <div class="flex items-center gap-2">
                <button type="button" data-product-id="${i.product_id}" data-action="dec"
                  class="w-9 h-9 rounded-full bg-gray-200 hover:bg-gray-300 flex items-center justify-center font-bold">−</button>
                <span class="w-8 text-center font-semibold">${i.quantity}</span>
                <button type="button" data-product-id="${i.product_id}" data-action="inc"
                  class="w-9 h-9 rounded-full bg-orange-500 text-white hover:bg-orange-600 flex items-center justify-center font-bold">+</button>
              </div>
            </div>
          `
        )
        .join('');
    }

    if (footer) footer.classList.remove('hidden');
    if (totalEl) totalEl.textContent = `KSh ${this.getCartTotal()}`;

    items?.querySelectorAll('[data-action]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const id = parseInt(btn.getAttribute('data-product-id'), 10);
        const action = btn.getAttribute('data-action');
        this.updateQuantity(id, action === 'inc' ? 1 : -1);
        this.renderCart();
      });
    });
  },

  initCheckout() {
    const empty = document.getElementById('checkout-empty');
    const form = document.getElementById('checkout-form');
    const summary = document.getElementById('checkout-summary');
    const totalEl = document.getElementById('checkout-total');

    if (this.cart.length === 0) {
      if (empty) empty.classList.remove('hidden');
      if (form) form.classList.add('hidden');
      return;
    }

    if (empty) empty.classList.add('hidden');
    if (form) form.classList.remove('hidden');

    const lines = this.cart.map((i) => `• ${i.quantity} × ${i.name}`).join('<br>');
    if (summary) summary.innerHTML = lines;
    if (totalEl) totalEl.textContent = `KSh ${this.getCartTotal()}`;

    form?.addEventListener('submit', (e) => this.handleCheckout(e));
  },

  async handleCheckout(e) {
    e.preventDefault();

    const token = getAccessToken();
    if (!token) {
      this.showToast('Please login to pay with M-Pesa', true);
      window.location.href = '/login';
      return;
    }

    const phoneInput = document.getElementById('phone');
    const phone = phoneInput?.value?.trim();
    if (!phone || !/^0[17]\d{8}$/.test(phone)) {
      this.showToast('Enter a valid M-Pesa number (07XXXXXXXX)', true);
      return;
    }

    const payBtn = document.getElementById('pay-btn');
    const payText = document.getElementById('pay-btn-text');
    const payLoading = document.getElementById('pay-btn-loading');

    if (payBtn) payBtn.disabled = true;
    if (payText) payText.classList.add('hidden');
    if (payLoading) payLoading.classList.remove('hidden');

    try {
      const orderRes = await fetch(apiUrl('/api/orders'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          items: this.cart.map((i) => ({
            product_id: parseInt(i.product_id, 10),
            name: i.name,
            price: parseInt(i.price, 10),
            quantity: parseInt(i.quantity, 10),
          })),
          phone_number: phone,
        }),
      });

      const orderJson = await orderRes.json();
      if (!orderRes.ok) {
        throw new Error(orderJson.message || orderJson.errors?.phone_number?.[0] || 'Order failed');
      }

      const orderId = orderJson.data?.id;
      if (!orderId) throw new Error('Invalid order response');

      const stkRes = await fetch(apiUrl('/api/mpesa/stkpush'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ order_id: orderId }),
      });

      const stkJson = await stkRes.json();
      if (!stkRes.ok || stkJson.status === 'error') {
        throw new Error(stkJson.message || 'M-Pesa request failed');
      }

      this.clearCart();
      window.location.href = `/order/${orderId}/status`;
    } catch (err) {
      this.showToast(err.message || 'Something went wrong', true);
    } finally {
      if (payBtn) payBtn.disabled = false;
      if (payText) payText.classList.remove('hidden');
      if (payLoading) payLoading.classList.add('hidden');
    }
  },

  initOrderStatus(orderId) {
    const loading = document.getElementById('status-loading');
    const waiting = document.getElementById('status-waiting');
    const success = document.getElementById('status-success');
    const failed = document.getElementById('status-failed');

    const receiptEl = document.getElementById('receipt-number');
    const whatsappBtn = document.getElementById('whatsapp-confirm-btn');

    const token = getAccessToken();

    let orderData = null;
    let pollCount = 0;
    const maxPoll = 60;
    const pollInterval = 2000;

    const show = (id) => {
      [loading, waiting, success, failed].forEach((el) => {
        if (el) el.classList.add('hidden');
      });
      const target = document.getElementById(id);
      if (target) target.classList.remove('hidden');
    };

    const pollStatus = async () => {
      try {
        const headers = token ? { Authorization: `Bearer ${token}` } : {};
        const res = await fetch(apiUrl(`/api/orders/${orderId}`), { headers });
        const json = await res.json();

        if (!res.ok) {
          show('status-failed');
          if (res.status === 404 && !token) {
            this.showToast('Please login to view this order', true);
          }
          return;
        }

        orderData = json.data;

        if (orderData.payment_status === 'paid') {
          show('status-success');
          if (receiptEl && orderData.mpesa_receipt) {
            receiptEl.textContent = `Receipt: ${orderData.mpesa_receipt}`;
          }
          if (whatsappBtn) {
            whatsappBtn.onclick = () => this.openWhatsAppConfirm(orderData);
          }
          return;
        }

        if (orderData.payment_status === 'failed') {
          show('status-failed');
          return;
        }
      } catch {
        // keep polling
      }

      pollCount++;
      if (pollCount < maxPoll) {
        setTimeout(pollStatus, pollInterval);
      } else {
        show('status-waiting');
      }
    };

    const fetchOrder = async () => {
      try {
        const headers = token ? { Authorization: `Bearer ${token}` } : {};
        const res = await fetch(apiUrl(`/api/orders/${orderId}`), { headers });
        const json = await res.json();
        if (!res.ok) throw new Error('Not found');
        orderData = json.data;

        if (orderData.payment_status === 'paid') {
          show('status-success');
          if (receiptEl && orderData.mpesa_receipt) {
            receiptEl.textContent = `Receipt: ${orderData.mpesa_receipt}`;
          }
          if (whatsappBtn) {
            whatsappBtn.onclick = () => this.openWhatsAppConfirm(orderData);
          }
          return;
        }

        if (orderData.payment_status === 'failed') {
          show('status-failed');
          return;
        }

        show('status-waiting');
        setTimeout(pollStatus, pollInterval);
      } catch {
        show('status-failed');
      }
    };

    fetchOrder();
  },

  buildWhatsAppMessage(items, total, phone) {
    const lines = items.map((i) => `• ${i.quantity} ${i.name}`).join('\n');
    const phoneLine = phone ? `\nPhone: ${phone}` : '';
    return `Hi Akira Bites, I want to order:\n\n${lines}\n\nTotal: KSh ${total}${phoneLine}`.slice(0, 1000);
  },

  launchWhatsAppForCart() {
    const msg = this.buildWhatsAppMessage(this.cart, this.getCartTotal(), null);
    const url = `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(msg)}`;
    const win = window.open(url, '_blank');

    if (win) {
      this.clearCart();
      this.renderCart();
      window.location.href = '/menu';
      return true;
    }

    return false;
  },

  initCartWhatsAppButton() {
    const btn = document.getElementById('cart-whatsapp-btn');
    if (!btn) return;

    btn.addEventListener('click', () => {
      if (this.cart.length === 0) return;
      const ok = this.launchWhatsAppForCart();
      if (!ok) this.showToast('Could not open WhatsApp. Please enable popups.', true);
    });
  },

  initCartWhatsApp() {
    this.initCartWhatsAppButton();
  },

  openWhatsAppConfirm(orderData) {
    const msg = this.buildWhatsAppMessage(orderData.items, orderData.total_amount, orderData.phone_number);
    const url = `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(msg)}`;
    window.open(url, '_blank');
  },

  showToast(message, isError = false) {
    const toast = document.createElement('div');
    toast.className = `fixed bottom-4 left-4 right-4 mx-auto max-w-md py-3 px-4 rounded-xl shadow-lg text-white text-center z-50 ${
      isError ? 'bg-red-600' : 'bg-[#E55A2B]'
    }`;
    toast.textContent = message;
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 3000);
  },
};

if (typeof window !== 'undefined') {
  window.OrderApp = OrderApp;
}

