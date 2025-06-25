let items = [];
let filteredItems = [];
let currentImgSize = 120;
let options = {};
let currentFocusIndex = -1; // Für Keyboard-Navigation

const bookContainer = document.querySelector('.book-container');
const itemsGrid = document.getElementById('itemsGrid');
const searchInput = document.getElementById('searchInput');
const typeFilter = document.getElementById('typeFilter');
const imgSizeRange = document.getElementById('imgSizeRange');
const imgSizeLabel = document.getElementById('imgSizeLabel');
const closeBtn = document.getElementById('closeBtn');

// Keyboard-Event-Handler
function handleKeyDown(event) {
    if (!bookContainer.style.display || bookContainer.style.display === 'none') return;
    
    switch(event.key) {
        case 'Escape':
            event.preventDefault();
            closeItemViewer();
            break;
        case 'ArrowLeft':
            event.preventDefault();
            navigateItems('left');
            break;
        case 'ArrowRight':
            event.preventDefault();
            navigateItems('right');
            break;
        case 'ArrowUp':
            event.preventDefault();
            navigateItems('up');
            break;
        case 'ArrowDown':
            event.preventDefault();
            navigateItems('down');
            break;
        case 'Enter':
            event.preventDefault();
            if (currentFocusIndex >= 0 && currentFocusIndex < filteredItems.length) {
                const item = filteredItems[currentFocusIndex];
                fetch(`https://${GetParentResourceName()}/giveItem`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ itemName: item.item })
                }).catch(err => {
                    console.error(`Fehler beim Senden von giveItem für ${item.item}:`, err);
                });
            }
            break;
    }
}

function navigateItems(direction) {
    if (filteredItems.length === 0) return;
    
    const containerWidth = itemsGrid.clientWidth;
    const itemFullWidth = currentImgSize + 40;
    const columnsCount = Math.floor(containerWidth / itemFullWidth) || 1;
    
    let newIndex = currentFocusIndex;
    
    switch(direction) {
        case 'left':
            newIndex = Math.max(0, currentFocusIndex - 1);
            break;
        case 'right':
            newIndex = Math.min(filteredItems.length - 1, currentFocusIndex + 1);
            break;
        case 'up':
            newIndex = Math.max(0, currentFocusIndex - columnsCount);
            break;
        case 'down':
            newIndex = Math.min(filteredItems.length - 1, currentFocusIndex + columnsCount);
            break;
    }
    
    if (newIndex !== currentFocusIndex) {
        setItemFocus(newIndex);
    }
}

function setItemFocus(index) {
    // Entferne vorherigen Fokus
    const prevFocused = document.querySelector('.item-wrapper.focused');
    if (prevFocused) {
        prevFocused.classList.remove('focused');
    }
    
    currentFocusIndex = index;
    
    if (index >= 0 && index < filteredItems.length) {
        const itemWrappers = document.querySelectorAll('.item-wrapper');
        if (itemWrappers[index]) {
            itemWrappers[index].classList.add('focused');
            itemWrappers[index].scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        }
    }
}

function closeItemViewer() {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });

    bookContainer.classList.add('fade-out');

    setTimeout(() => {
        bookContainer.style.display = 'none';
        bookContainer.classList.remove('fade-out');
        itemsGrid.innerHTML = '';
        hideTooltip();
        currentFocusIndex = -1;
    }, 300);
}

// Event-Listener für Keyboard
document.addEventListener('keydown', handleKeyDown);

function formatBool(value) {
  return value ? 'Ja' : 'Nein';
}

function populateTypeFilter() {
  const types = [...new Set(items.map(i => i.type))].sort();
  typeFilter.innerHTML = `<option value="all">Alle Typen</option>` +
    types.map(t => `<option value="${t}">${t}</option>`).join('');
}

function filterItems() {
  const term = searchInput.value.toLowerCase();
  const type = typeFilter.value;

  filteredItems = items.filter(item => {
    const label = item.label || item.item || '';
    const description = item.description || '';
    const matchTerm = label.toLowerCase().includes(term) || description.toLowerCase().includes(term);
    const matchType = (type === 'all' || item.type === type);
    return matchTerm && matchType;
  });

  renderItems();
}

const failedImages = new Set(); // Para registrar qué URLs ya fallaron

function renderItems() {
  itemsGrid.innerHTML = '';
  currentFocusIndex = -1; // Reset focus

  // Sortierung immer nach label (Datenbank), fallback item
  filteredItems.sort((a, b) => {
    const nameA = (a.label || a.item || '').toLowerCase();
    const nameB = (b.label || b.item || '').toLowerCase();
    if (nameA < nameB) return -1;
    if (nameA > nameB) return 1;
    return 0;
  });

  const containerWidth = itemsGrid.clientWidth;
  const itemFullWidth = currentImgSize + 40;
  const itemFullHeight = currentImgSize + 90;
  const columnsCount = Math.floor(containerWidth / itemFullWidth) || 1;

  const containerHeight = itemsGrid.clientHeight;
  const sizeMin = 130;
  const sizeMax = 190;
  const rowsMin = 2;
  const rowsMax = 5;
  const m = (rowsMax - rowsMin) / (sizeMax - sizeMin);
  const b = rowsMin - m * sizeMin;
  let rowsCount = Math.round(m * currentImgSize + b);
  rowsCount = Math.max(rowsMin, Math.max(rowsMax, rowsCount));

  itemsGrid.style.maxHeight = `${rowsCount * itemFullHeight}px`;
  itemsGrid.style.overflowY = 'auto'; // si quieres scroll vertical cuando hay más filas

  filteredItems.forEach((item, idx) => {
    const wrapper = document.createElement('div');
    wrapper.className = 'item-wrapper';
    if (item.unique) wrapper.classList.add('unique-item');
    wrapper.classList.add('image-error');
    wrapper.style.width = `${itemFullWidth}px`;
    wrapper.style.height = `${itemFullHeight}px`;

    // Prüfen, ob dies das letzte Item in der aktuellen Reihe ist
    if (((idx + 1) % columnsCount === 0)) {
      wrapper.setAttribute('data-last-in-row', 'true');
    }

    const img = document.createElement('div');
    img.className = 'item-image';
    img.style.width = `${currentImgSize}px`;
    img.style.height = `${currentImgSize}px`;
  
    const imgTag = document.createElement('img');
    let hasErrored = false;
    const defaultImage = 'bread.png';
    const imageUrl = item.imageUrl && item.imageUrl.trim() !== '' ? item.imageUrl : defaultImage;
    imgTag.src = imageUrl;
    imgTag.alt = item.label || item.item || 'Ítem';
  
    imgTag.onerror = () => {
      if (!hasErrored) {
        hasErrored = true;
        if (!failedImages.has(imgTag.src)) {
          failedImages.add(imgTag.src);
          console.warn(`Bild nicht gefunden für: ${item.item} (${imgTag.src})`);
        }
        imgTag.src = defaultImage;
      } else {
        imgTag.onerror = null;
      }
    };

    imgTag.addEventListener('click', () => {
      fetch(`https://${GetParentResourceName()}/giveItem`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ itemName: item.item })
      }).catch(err => {
        console.error(`Fehler beim Senden von giveItem für ${item.item}:`, err);
      });
    });
  
    img.appendChild(imgTag);
    wrapper.appendChild(img);

    const nameDiv = document.createElement('div');
    nameDiv.className = 'item-name';
    nameDiv.textContent = (options.showLabel && item.label) ? item.label :
                          (options.showName && item.item) ? item.item : '';
    wrapper.appendChild(nameDiv);

    wrapper.addEventListener('mouseenter', (e) => showTooltip(e, item));
    wrapper.addEventListener('mouseleave', hideTooltip);
    
    // Keyboard-Fokus-Handler
    wrapper.addEventListener('click', () => {
      setItemFocus(idx);
    });

    itemsGrid.appendChild(wrapper);
  });
}

const slider = document.getElementById('imgSizeRange');
const label = document.getElementById('imgSizeLabel');

function updateLabel() {
  const value = slider.value;
  label.textContent = `${value} x ${value}`;

  const controlsRect = slider.parentElement.getBoundingClientRect(); // contenedor .controls
  const sliderRect = slider.getBoundingClientRect();

  const min = slider.min ? slider.min : 0;
  const max = slider.max ? slider.max : 100;
  const percent = (value - min) / (max - min);

  const sliderWidth = sliderRect.width;
  const labelWidth = label.offsetWidth;

  // Posición del thumb dentro del slider:
  let left = percent * sliderWidth - labelWidth / 2;

  // Evitar que el label se salga de .controls
  if (left < 0) left = 0;
  if (left > sliderWidth - labelWidth) left = sliderWidth - labelWidth;

  label.style.left = `${left}px`;
}

slider.addEventListener('input', updateLabel);
window.addEventListener('resize', updateLabel);

updateLabel();
slider.addEventListener('input', updateLabel);
window.addEventListener('resize', updateLabel);

updateLabel();

imgSizeRange.addEventListener('input', () => {
  currentImgSize = parseInt(imgSizeRange.value);
  imgSizeLabel.textContent = `${currentImgSize} x ${currentImgSize}`;
  renderItems();
});

searchInput.addEventListener('input', filterItems);
typeFilter.addEventListener('change', filterItems);

closeBtn.addEventListener('click', closeItemViewer);

window.addEventListener('message', event => {
  const data = event.data;
  console.log('Message event:', data); // Debug-Ausgabe
  if (data.action === 'open') {
    bookContainer.style.display = 'flex';
    // Fokus auf erstes Item setzen
    setTimeout(() => {
      if (filteredItems.length > 0) {
        setItemFocus(0);
      }
    }, 100);
  } else if (data.action === 'close') {
    bookContainer.style.display = 'none';
    hideTooltip();
    currentFocusIndex = -1;
  } else if (data.action === 'loadItems') {
    options = data.options || {};
    items = data.items ? Object.values(data.items) : [];
    populateTypeFilter();
    filterItems();
  } else if (data.action === 'setAdmin') {
    window.isItemViewerAdmin = data.isAdmin;
  } else if (data.action === 'liveUpdateItem') {
    // Item in items/filteredItems aktualisieren
    const idx = items.findIndex(i => i.item === data.item);
    if (idx !== -1) items[idx] = { ...items[idx], ...data };
    const fidx = filteredItems.findIndex(i => i.item === data.item);
    if (fidx !== -1) filteredItems[fidx] = { ...filteredItems[fidx], ...data };
    renderItems();
  }
});

// Globaler Tooltip
const globalTooltip = document.createElement('div');
globalTooltip.className = 'tooltip';
globalTooltip.style.position = 'fixed';
globalTooltip.style.zIndex = '9999';
globalTooltip.style.display = 'none'; // Tooltip standardmäßig ausblenden
document.body.appendChild(globalTooltip);

function showTooltip(event, item) {
  const tooltipHTML = `
    <strong>${item.label || item.item}</strong><br>
    <span class="item-desc-small">${item.description || 'Keine Beschreibung'}</span><br><br>
    <strong>Item:</strong> ${item.item}<br>
    <strong>Gewicht:</strong> ${item.weight || 0}
  `;

  globalTooltip.innerHTML = tooltipHTML;
  globalTooltip.style.display = 'block';
  globalTooltip.style.width = '210px';

  const tooltipRect = globalTooltip.getBoundingClientRect();
  const viewportWidth = window.innerWidth;
  const viewportHeight = window.innerHeight;

  // Das Element, über dem die Maus ist (der Wrapper)
  const targetRect = event.currentTarget.getBoundingClientRect();
  const isLastInRow = event.currentTarget.getAttribute('data-last-in-row') === 'true';

  const offset = 10; // Abstand zwischen Bild und Tooltip

  let left, top;

  // Wenn letztes Bild in der Reihe, Tooltip immer links anzeigen
  if (isLastInRow) {
    left = targetRect.left - offset - tooltipRect.width;
    // Falls zu weit links, am linken Rand ausrichten
    if (left < offset) left = offset;
  } else {
    // Standard-Logik: Tooltip rechts, wenn Platz, sonst links, sonst am rechten Rand
    if (targetRect.right + offset + tooltipRect.width < viewportWidth) {
      left = targetRect.right + offset;
    } else if (targetRect.left - offset - tooltipRect.width > 0) {
      left = targetRect.left - offset - tooltipRect.width;
    } else {
      left = viewportWidth - tooltipRect.width - offset;
    }
  }

  // Vertikale Positionierung wie gehabt
  if (targetRect.top + tooltipRect.height < viewportHeight) {
    top = targetRect.top;
  } else if (targetRect.bottom - tooltipRect.height > 0) {
    top = targetRect.bottom - tooltipRect.height;
  } else {
    top = offset;
  }
  if (top < offset) top = offset;
  if (top + tooltipRect.height > viewportHeight) top = viewportHeight - tooltipRect.height - offset;

  globalTooltip.style.left = `${left}px`;
  globalTooltip.style.top = `${top}px`;
}

function hideTooltip() {
  globalTooltip.style.display = 'none';
}

// Setze die minimalen/maximalen Werte für den Slider
imgSizeRange.min = 130;
imgSizeRange.max = 190;
imgSizeRange.value = 130;
imgSizeRange.step = 10;

// --- ADMIN-EDITIERUNG ---
// Admin-Status (muss vom Server gesetzt werden!)
window.isItemViewerAdmin = false;

// Modal-Elemente
const editItemModal = document.getElementById('editItemModal');
const closeEditModal = document.getElementById('closeEditModal');
const editItemForm = document.getElementById('editItemForm');
const editItemError = document.getElementById('editItemError');

let currentEditItem = null;

function openEditModal(item) {
  if (!window.isItemViewerAdmin) return;
  currentEditItem = item;
  editItemModal.style.display = 'flex';
  editItemError.style.display = 'none';
  // Felder befüllen
  editItemForm.editItem_item.value = item.item || '';
  editItemForm.editItem_label.value = item.label || '';
  editItemForm.editItem_description.value = item.description || '';
  editItemForm.editItem_weight.value = item.weight || 0;
  editItemForm.editItem_type.value = item.type || '';
  editItemForm.editItem_unique.checked = !!item.unique;
  editItemForm.editItem_useable.checked = !!item.useable;
  editItemForm.editItem_decay.value = item.decay || '';
  editItemForm.editItem_delete.checked = !!item.delete;
  editItemForm.editItem_shouldClose.checked = !!item.shouldClose;
}

function closeEditItemModal() {
  editItemModal.style.display = 'none';
  currentEditItem = null;
}

closeEditModal.addEventListener('click', closeEditItemModal);
window.addEventListener('click', function(event) {
  if (event.target === editItemModal) closeEditItemModal();
});

// Formular absenden
editItemForm.addEventListener('submit', function(e) {
  e.preventDefault();
  if (!window.isItemViewerAdmin) return;
  const data = {
    item: editItemForm.editItem_item.value,
    label: editItemForm.editItem_label.value,
    description: editItemForm.editItem_description.value,
    weight: parseFloat(editItemForm.editItem_weight.value) || 0,
    type: editItemForm.editItem_type.value,
    unique: editItemForm.editItem_unique.checked,
    useable: editItemForm.editItem_useable.checked,
    decay: editItemForm.editItem_decay.value,
    delete: editItemForm.editItem_delete.checked,
    shouldClose: editItemForm.editItem_shouldClose.checked
  };
  fetch(`https://${GetParentResourceName()}/editItem`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  }).then(res => res.json()).then(result => {
    if (result.success) {
      // Item in items/filteredItems aktualisieren
      const idx = items.findIndex(i => i.item === data.item);
      if (idx !== -1) items[idx] = { ...items[idx], ...data };
      const fidx = filteredItems.findIndex(i => i.item === data.item);
      if (fidx !== -1) filteredItems[fidx] = { ...filteredItems[fidx], ...data };
      renderItems();
      closeEditItemModal();
    } else {
      editItemError.textContent = result.error || 'Fehler beim Speichern!';
      editItemError.style.display = 'block';
    }
  }).catch(err => {
    editItemError.textContent = 'Fehler beim Speichern!';
    editItemError.style.display = 'block';
  });
});

// Rechtsklick auf Item-Wrapper (nur für Admins)
function addEditContextMenu(wrapper, item) {
  if (!window.isItemViewerAdmin) return;
  wrapper.addEventListener('contextmenu', function(e) {
    e.preventDefault();
    openEditModal(item);
  });
}

// Patch in renderItems: addEditContextMenu aufrufen
const origRenderItems = renderItems;
renderItems = function() {
  itemsGrid.innerHTML = '';
  currentFocusIndex = -1; // Reset focus
  const containerWidth = itemsGrid.clientWidth;
  const itemFullWidth = currentImgSize + 40;
  const itemFullHeight = currentImgSize + 90;
  const columnsCount = Math.floor(containerWidth / itemFullWidth) || 1;
  const containerHeight = itemsGrid.clientHeight;
  const sizeMin = 130;
  const sizeMax = 190;
  const rowsMin = 2;
  const rowsMax = 5;
  const m = (rowsMax - rowsMin) / (sizeMax - sizeMin);
  const b = rowsMin - m * sizeMin;
  let rowsCount = Math.round(m * currentImgSize + b);
  rowsCount = Math.max(rowsMin, Math.max(rowsMax, rowsCount));
  itemsGrid.style.maxHeight = `${rowsCount * itemFullHeight}px`;
  itemsGrid.style.overflowY = 'auto';
  filteredItems.forEach((item, idx) => {
    const wrapper = document.createElement('div');
    wrapper.className = 'item-wrapper';
    if (item.unique) wrapper.classList.add('unique-item');
    wrapper.classList.add('image-error');
    wrapper.style.width = `${itemFullWidth}px`;
    wrapper.style.height = `${itemFullHeight}px`;
    if (((idx + 1) % columnsCount === 0)) {
      wrapper.setAttribute('data-last-in-row', 'true');
    }
    const img = document.createElement('div');
    img.className = 'item-image';
    img.style.width = `${currentImgSize}px`;
    img.style.height = `${currentImgSize}px`;
    const imgTag = document.createElement('img');
    let hasErrored = false;
    const defaultImage = 'bread.png';
    const imageUrl = item.imageUrl && item.imageUrl.trim() !== '' ? item.imageUrl : defaultImage;
    imgTag.src = imageUrl;
    imgTag.alt = item.label || item.item || 'Ítem';
    imgTag.onerror = () => {
      if (!hasErrored) {
        hasErrored = true;
        if (!failedImages.has(imgTag.src)) {
          failedImages.add(imgTag.src);
          console.warn(`Bild nicht gefunden für: ${item.item} (${imgTag.src})`);
        }
        imgTag.src = defaultImage;
      } else {
        imgTag.onerror = null;
      }
    };
    imgTag.addEventListener('click', () => {
      fetch(`https://${GetParentResourceName()}/giveItem`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ itemName: item.item })
      }).catch(err => {
        console.error(`Fehler beim Senden von giveItem für ${item.item}:`, err);
      });
    });
    img.appendChild(imgTag);
    wrapper.appendChild(img);
    const nameDiv = document.createElement('div');
    nameDiv.className = 'item-name';
    nameDiv.textContent = (options.showLabel && item.label) ? item.label :
                          (options.showName && item.item) ? item.item : '';
    wrapper.appendChild(nameDiv);
    wrapper.addEventListener('mouseenter', (e) => showTooltip(e, item));
    wrapper.addEventListener('mouseleave', hideTooltip);
    wrapper.addEventListener('click', () => {
      setItemFocus(idx);
    });
    addEditContextMenu(wrapper, item);
    itemsGrid.appendChild(wrapper);
  });
  // Fokus auf erstes Item setzen
  setTimeout(() => {
    if (filteredItems.length > 0) {
      setItemFocus(0);
    }
  }, 100);
};
