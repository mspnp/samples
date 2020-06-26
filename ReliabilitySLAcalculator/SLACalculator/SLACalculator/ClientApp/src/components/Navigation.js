import React, { Component } from 'react';
import './Styles.css';

export class Navigation extends Component {

    constructor(props) {
        super(props);
    }

    static renderCategoriesTable(serviceCategories, selectedCategory, selectCategory) {
        console.log(selectedCategory)
        return (
            <table className='table table-striped' aria-labelledby="tabelLabel">
                <tbody>
                    {serviceCategories.map(serviceCategory =>
                        <tr key={serviceCategory.categoryName}>
                            <td className={selectedCategory === serviceCategory.categoryName ? "selectedcategorymenu-item" :"categorymenu-item"} onClick={() => selectCategory(serviceCategory)}>{serviceCategory.categoryName}</td>
                        </tr>
                    )}
                </tbody>
            </table>
        );
    }

    render() {
        let contents = Navigation.renderCategoriesTable(this.props.dataSource, this.props.selectedCategory, this.props.onSelectCategory);
        //let contents = this.state.loading
        //    ? <p><em>Loading...</em></p>
        //    : Navigation.renderCategoriesTable(this.props.serviceCategory, this.props.selectCategory);
        return (
            <div>
                {contents}
            </div>
        );
    }
}
